defmodule ArkTbwDelegateServer.Calculations do
  @div Decimal.new(100000000.0)
  @zero Decimal.new(0)

  import ArkTbwDelegateServer.Utils

  alias ArkElixir.Util.TransactionBuilder
  alias ArkTbwDelegateServer.{Audit, Ledger}

  def build_ledger(account, client) do
    loading(
      "Building ledger for voter #{account.address}",
      "Built ledger for voter #{account.address}",
      fn -> Ledger.build(account, client) end
    )
  end

  def calculate(ledger, %{blocks: blocks, voter_share: voter_share} = opts) do
    loading_message =
      "Calculating disbursement amounts for #{ledger.account.address}"
    loaded_message =
      "Calculated disbursement amounts for #{ledger.account.address}"

    Audit.write(
      opts.audit,
      "=====================================================================" <>
      "\n#{loading_message}\n\nAccount:"
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
      loading(loading_message, loaded_message, fn ->
        first_block = List.first(blocks).height
        last_block = List.last(blocks).height
        Audit.write(opts.audit,
  """
  Current Balance: #{balance}
  Blocks to be processed: #{last_block} - #{first_block}

  Calculating rewards...
  """
        )

        reward = @zero

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
            message = "Account #{ledger.account.address} (Ѧ #{balance}) " <>
              "gets Ѧ #{Decimal.to_string(reward, :normal)} rewards for " <>
              "blocks #{last_block} - #{first_block}."
            Audit.write(opts.audit, "#{message}\n")
            %{
              amount: reward,
              audit_message: message,
              balance: balance,
              delegate: delegate_cut,
              from: last_block,
              height: first_block,
              ledger: ledger,
              type: :disbursed
            }
          _ ->
            message = "Account #{ledger.account.address} (Ѧ #{balance}) " <>
              "has banked Ѧ #{Decimal.to_string(reward, :normal)} rewards " <>
              "for blocks #{last_block} - #{first_block}."
            Audit.write(opts.audit, "#{message}\n")
            %{
              amount: reward,
              audit_message: message,
              balance: balance,
              delegate: delegate_cut,
              from: last_block,
              height: first_block,
              ledger: ledger,
              type: :banked,
            }
        end
      end)
    else
      Audit.write(opts.audit, "No new blocks found")

      message = "Account #{ledger.account.address} (Ѧ #{balance}) has " <>
                "banked Ѧ 0.0 rewards (no unpaid blocks found)."

      %{
        amount: @zero,
        audit_message: message,
        balance: @zero,
        delegate: @zero,
        from: 0,
        height: 0,
        ledger: ledger,
        type: :banked,
      }
    end
  end

  # private

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
end
