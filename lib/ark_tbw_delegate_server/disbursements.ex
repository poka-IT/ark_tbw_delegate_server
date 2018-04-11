defmodule ArkTbwDelegateServer.Disbursements do
  @div Decimal.new(100000000.0)
  @fee Decimal.new(0.1)
  @throttle 10000 # 10 seconds

  import ArkTbwDelegateServer.Utils

  alias ArkElixir.Util.TransactionBuilder
  alias ArkTbwDelegateServer.{Audit, Delegate, Ledger, Logger}

  def list(opts) do
    Logger.debug(opts)
    IO.puts "I'm a list!"
  end

  def run(%{
    client: client,
    delegate_public_key: public_key
  } = opts) do
    clear()

    Bunt.puts([
      :blue,
      :bright,
      "    Loading forged blocks (this may take a while)... "
    ])

    blocks = Delegate.forged(opts)

    {:ok, voters} = ArkElixir.Delegate.voters(client, public_key)
    voters = Enum.map(voters, &build_ledger(&1, client))

    opts =
      opts
      |> Map.put(:blocks, blocks)
      |> Map.put(:voters, voters)

    statements =
      voters
      |> Enum.map(&calculate(&1, opts))
      |> Enum.reject(&is_nil/1)

    if Enum.count(statements) > 0 do
      Enum.each(statements, &Bunt.puts(&1.display))
      print_balances_due(statements, opts)
      confirm_and_disburse(statements, opts)
    else
      Bunt.puts([:orange, :bright, "    No new blocks found."])
    end
  end

  # private

  defp build_ledger(account, client) do
    Bunt.puts([
      :blue,
      :bright,
      "    Building ledger for voter #{account.address}"
    ])
    Ledger.build(account, client)
  end

  defp calculate(ledger, %{blocks: blocks, voter_share: voter_share} = opts) do
    message =
      "Calculating disbursement amounts for #{ledger.account.address}..."

    Audit.write(
      opts.audit,
      "=====================================================================" <>
      "\n#{message}\n\nAccount:"
    )
    Audit.write(opts.audit, ledger.account)
    Audit.write(opts.audit,
"""
\nTotal Transactions: #{Enum.count(ledger.transactions)}

Breakdown:
---
Delegate: #{Enum.count(ledger.__type_index__.delegate)}
Multisignature: #{Enum.count(ledger.__type_index__.multisignature)}
Second Signature: #{Enum.count(ledger.__type_index__.second_signature)}
Transfer: #{Enum.count(ledger.__type_index__.transfer)}
Vote: #{Enum.count(ledger.__type_index__.vote)}
---
"""
    )

    Bunt.puts([:blue, :bright, "    #{message}"])


    balance =
      ledger
      |> Ledger.balance
      |> Decimal.new
      |> Decimal.div(@div)
      |> Decimal.to_string(:normal)

    # find the last disbursement and use next block as initial_block_height or
    #   use global initial_block_height
    blocks = Ledger.filter_unpaid(ledger, blocks)
    # calculate fees due since initial_block_height

    if Enum.count(blocks) > 0 do
      first_block = List.first(blocks).height
      last_block = List.last(blocks).height
      Audit.write(opts.audit,
"""
Current Balance: #{balance}
Blocks to be processed: #{last_block} - #{first_block}

Calculating rewards...
"""
      )

      reward = Decimal.new(0)

      full_reward =
        Enum.reduce(blocks, reward, &calculate_reward(ledger, &1, &2, opts))

      reward =
        full_reward
        |> Decimal.mult(Decimal.new(voter_share)) # Take out delegate's cut
        |> fn(share) ->
          message = "Total reward after delegate's cut (#{voter_share}) #{share}"
          Audit.write(opts.audit, "\n#{message}")
          share
        end.()
        |> Decimal.round(0)
        |> Decimal.div(@div)

      delegate_share = 1 |> Decimal.new |> Decimal.sub(Decimal.new(voter_share))

      delegate_cut =
        full_reward
        |> Decimal.mult(delegate_share)
        |> fn(share) ->
          message = "Delegate's cut (#{delegate_share}) #{share}"
          Audit.write(opts.audit, "\n#{message}")
          share
        end.()
        |> Decimal.round(0)
        |> Decimal.div(@div)

      threshold = opts |> Map.get(:payout_threshold) |> Decimal.new

      case Decimal.cmp(reward, threshold) do
        :gt ->
          message = "Account #{ledger.account.address} (Ѧ #{balance}) gets " <>
                    "Ѧ #{Decimal.to_string(reward, :normal)} rewards for " <>
                    "blocks #{last_block} - #{first_block}."
          Audit.write(opts.audit, "#{message}\n")
          %{
            amount: reward,
            delegate: delegate_cut,
            display: [:green, :bright, "    #{message}"],
            height: first_block,
            ledger: ledger,
            type: :disbursed,
          }
        _ ->
          message = "Account #{ledger.account.address} (Ѧ #{balance}) has " <>
                    "banked Ѧ #{Decimal.to_string(reward, :normal)} rewards " <>
                    "for blocks #{last_block} - #{first_block}."
          Audit.write(opts.audit, "#{message}\n")
          %{
            amount: reward,
            delegate: delegate_cut,
            display: [:orange, :bright, "    #{message}"],
            height: first_block,
            ledger: ledger,
            type: :banked,
          }
      end
    else
      Audit.write(opts.audit, "No new blocks found")
      nil
    end
  end

  defp calculate_reward(ledger, block, current_reward, opts) do
    timestamp = TransactionBuilder.ark_epoch() + block.timestamp
    # Audit.write(opts.audit, "Timestamp: #{block.timestamp}")
    current_delegate = Ledger.delegate_at(ledger, timestamp)
    if current_delegate == opts.delegate.public_key do
      balance = Ledger.balance_at(ledger, timestamp)

      pool_balance =
        Enum.reduce(opts.voters, 0, fn(voter, total) ->
          # Audit.write(opts.audit, "#{voter.account.address} #{total}")
          voter_delegate = Ledger.delegate_at(voter, timestamp)
          if voter_delegate == opts.delegate.public_key do
            voter_balance = Ledger.balance_at(voter, timestamp)
            total + voter_balance
          else
            total
          end
        end)

      weight = Decimal.div(balance, pool_balance)
      cut = Decimal.mult(block.total_forged, weight)

      Audit.write(
        opts.audit,
        "Block #{block.height} - Adding reward #{cut} at weight " <>
        "#{weight} (#{balance} / #{pool_balance})"
      )

      Decimal.add(current_reward, cut)
    else
      Audit.write(
        opts.audit,
        "Block #{block.height} - No reward (not a voter when block " <>
        "forged)"
      )

      current_reward
    end
  end

  defp confirm_and_disburse(statements, opts) do
    case receive_input("Would you like to disburse the funds? (YN)") do
      "Y" -> disburse(statements, opts)
      "y" -> disburse(statements, opts)
      _ -> :noop
    end
  end

  defp disburse(statements, opts) do
    disburse = Enum.filter(statements, &(&1.type == :disbursed))
    count = Enum.count(disburse)

    format = [
      bar_color: [IO.ANSI.white, IO.ANSI.green_background],
      blank_color: IO.ANSI.red_background,
    ]

    Bunt.puts([
      :green,
      :bright,
      "    Press CTRL-C in the next 10 seconds to abort.\n"
    ])

    Enum.reduce(disburse, 0, fn(statement, counter) ->
      arktoshis =
        statement
        |> Map.get(:amount)
        |> Decimal.mult(@div)
        |> Decimal.round(8)
        |> Decimal.to_integer

      message = "(#{counter+1}/#{count}) Disbursing Ѧ " <>
        "#{Decimal.to_string(statement.amount, :normal)} (#{arktoshis} " <>
        "arktoshi) to #{statement.ledger.account.address} in 10 seconds."

      Audit.write(opts.audit, message)

      ProgressBar.render(counter, count, format)

      Process.sleep(@throttle)

      result = ArkElixir.Transaction.create(
        opts.client,
        statement.ledger.account.address,
        arktoshis,
        "#{opts.delegate.username} | payout to height #{statement.height}",
        opts.private_key
      )
      Audit.write(opts.audit, result)

      counter + 1
    end)

    ProgressBar.render(count, count, format)
  end

  defp print_balances_due(statements, opts) do
    blank = %{
      banked: Decimal.new(0),
      delegate: Decimal.new(0),
      disbursed: Decimal.new(0),
      fees: @fee
    }

    %{banked: banked, delegate: delegate, disbursed: disbursed, fees: fees} =
      Enum.reduce(statements, blank, fn
        %{amount: amount, delegate: delegate, type: :banked}, totals ->
          totals
          |> Map.put(:banked, Decimal.add(totals.banked, amount))
          |> Map.put(:delegate, Decimal.add(totals.delegate, delegate))
        %{amount: amount, delegate: delegate, type: :disbursed}, totals ->
          totals
          |> Map.put(:delegate, Decimal.add(totals.delegate, delegate))
          |> Map.put(:disbursed, Decimal.add(totals.disbursed, amount))
          |> Map.put(:fees, Decimal.add(totals.fees, @fee))
      end)

    delegate_cut =
      delegate
      |> Decimal.sub(fees) # TODO: This is delegate paying fee
      |> Decimal.to_string(:normal)

    total =
      banked
      |> Decimal.add(delegate_cut)
      |> Decimal.add(disbursed) # TODO: Subtract fees if voter pays
      |> Decimal.add(fees)
      |> Decimal.to_string(:normal)

    messages = [
      "---",
      "Totals:",
      "All: #{total}",
      "Banked: #{Decimal.to_string(banked, :normal)}",
      "Disbursed: #{Decimal.to_string(disbursed, :normal)}",
      "Delegate's Cut: #{delegate_cut}",
      "Fees Reserved: #{Decimal.to_string(fees, :normal)}\n    ---\n"
    ]

    Enum.each(messages, fn(message) ->
      Bunt.puts([:white, :bright, "    #{message}"])
      Audit.write(opts.audit, message)
    end)
  end
end
