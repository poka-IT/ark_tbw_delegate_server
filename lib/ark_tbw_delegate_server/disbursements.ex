defmodule ArkTbwDelegateServer.Disbursements do
  @div Decimal.new(100000000.0)
  @fee Decimal.new(0.1)
  @throttle 5000 # 5 seconds

  import ArkTbwDelegateServer.Utils
  import ArkTbwDelegateServer.Calculations

  alias ArkElixir.Client
  alias ArkElixir.Util.TransactionBuilder
  alias ArkTbwDelegateServer.{Audit, Delegate, Ledger}

  def list(
    %{client: client, delegate: %{username: name}, delegate_address: address}
  ) do
    clear()
    motd()

    delegate_ledger =
      loading(
        "Loading #{name}'s transaction history",
        "Loaded #{name}'s transaction history",
        fn -> Ledger.build(address, client) end
      )

    disbursements =
      loading(
        "Identifying disbursements",
        "Identified disbursements",
        fn ->
          delegate_ledger
          |> Ledger.disbursements
          |> Enum.reduce(%{}, fn(transaction, collection) ->
            set = Map.get(collection, transaction.recipient_id, [])
            Map.put(collection, transaction.recipient_id, [transaction] ++ set)
          end)
        end
      )

    Enum.each(disbursements, fn({address, transactions}) ->
      Bunt.puts([:green, :bright, "\n    #{address}"])
      Enum.each(transactions, fn(%{amount: amount, timestamp: timestamp}) ->
        amount =
          amount |> Decimal.new |> Decimal.div(@div) |> Decimal.to_string(:normal)

        dt =
          (timestamp + TransactionBuilder.ark_epoch())
          |> DateTime.from_unix!
          |> DateTime.to_string

        Bunt.puts([:green, :faint, "    Ѧ #{amount} sent on #{dt}"])
      end)
    end)
  end

  def run(%{client: client, delegate_public_key: public_key} = opts) do
    clear()
    motd()

    blocks = loading(
      "Loading forged blocks (this may take a while)",
      "Forged blocks loaded",
      fn -> Delegate.forged(opts) end
    )

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

    IO.puts("  ")

    if Enum.count(statements) > 0 do
      Enum.each(statements, fn
        %{type: :banked} = statement ->
          Bunt.puts([:orange, :bright, "    #{statement.audit_message}"])
        %{type: :disbursed} = statement ->
          Bunt.puts([:green, :bright, "    #{statement.audit_message}"])
      end)
      print_balances_due(statements, opts)
      confirm_and_disburse(statements, opts)
    else
      Bunt.puts([:orange, :bright, "    No voters found."])
    end
  end

  # private

  defp client_from_peer(peer, opts) do
    Client.new(%{
      ip: peer.ip,
      nethash: opts.nethash,
      network_address: opts.network_address,
      port: peer.port,
      protocol: "http", # :(
      version: peer.version
    })
  end

  defp confirm_and_disburse(statements, opts) do
    disbursable = Enum.filter(statements, &(&1.type == :disbursed))
    count = Enum.count(disbursable)

    if Enum.count(disbursable) > 0 do
      message =
        "Would you like to disburse the funds to #{count} accounts? (Y/N)"

      if opts.force do
        IO.puts("    #{message}: Y")
        disburse(disbursable, opts)
      else
        case receive_input(message) do
          "Y" -> disburse(disbursable, opts)
          "y" -> disburse(disbursable, opts)
          _ -> :noop
        end
      end
    else
      Bunt.puts([:orange, :bright, "    No new blocks found"])
    end
  end

  defp disburse(statements, opts) do
    count = Enum.count(statements)

    format = [
      bar_color: [IO.ANSI.light_blue(), IO.ANSI.light_blue_background()],
      blank: "-",
      blank_color: [IO.ANSI.light_blue(), IO.ANSI.light_black_background()],
      left: "    "
    ]

    Bunt.puts([
      :green,
      :bright,
      "    Press CTRL-C in the next 10 seconds to abort\n"
    ])

    Process.sleep(@throttle)

    Audit.write(opts.audit, "Fetching peer list")
    {:ok, peers} = ArkElixir.Peer.peers(opts.client)
    peers = Enum.map(peers, &client_from_peer(&1, opts)) ++ [opts.client]

    Enum.reduce(statements, 0, fn(statement, counter) ->
      arktoshis =
        statement
        |> Map.get(:amount)
        |> Decimal.mult(@div)
        |> Decimal.round(8)
        |> Decimal.to_integer

      message = "(#{counter+1}/#{count}) Disbursing Ѧ " <>
        "#{Decimal.to_string(statement.amount, :normal)} (#{arktoshis} " <>
        "arktoshi) to #{statement.ledger.account.address} in 5 seconds"

      Audit.write(opts.audit, message)
      count_string = " (#{counter}/#{count})"

      Process.sleep(@throttle)
      ProgressBar.render(counter, count, [right: count_string] ++ format)

      Audit.write(opts.audit, "Generating transaction...")

      transaction =
        statement
        |> Map.get(:ledger)
        |> Map.get(:account)
        |> Map.get(:address)
        |> TransactionBuilder.create_transfer(
          arktoshis,
          "#{opts.delegate.username} | payout to height #{statement.height}",
          opts.private_key,
          nil
        )
        |> TransactionBuilder.transaction_to_params

      Audit.write(opts.audit, transaction)

      Enum.each(peers, fn(peer) ->
        Kernel.spawn(fn() ->
          result = ArkElixir.post(
            peer,
            "peer/transactions",
            %{transactions: [transaction]}
          )
          Audit.write(opts.audit, result)
        end)
      end)

      Audit.write(opts.audit, "Transaction sent")

      counter + 1
    end)

    count_string = " (#{count}/#{count})"
    Process.sleep(@throttle)
    ProgressBar.render(count, count, [right: count_string] ++ format)
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
      if opts.fee_paid do # delegate pays the fee
        delegate |> Decimal.sub(fees) |> Decimal.to_string(:normal)
      else # voter pays the fee
        Decimal.to_string(delegate, :normal)
      end

    disbursed =
      if opts.fee_paid do
        Decimal.to_string(disbursed, :normal)
      else
        disbursed |> Decimal.sub(fees) |> Decimal.to_string(:normal)
      end

    total =
      banked
      |> Decimal.add(delegate_cut)
      |> Decimal.add(disbursed)
      |> Decimal.add(fees)
      |> Decimal.to_string(:normal)

    messages = [
      " ",
      "Totals:",
      "All: #{total}",
      "Banked: #{Decimal.to_string(banked, :normal)}",
      "Disbursed: #{disbursed}",
      "Delegate's Cut: #{delegate_cut}",
      "Fees Reserved: #{Decimal.to_string(fees, :normal)}\n"
    ]

    Enum.each(messages, fn(message) ->
      Bunt.puts([:white, :bright, "    #{message}"])
      Audit.write(opts.audit, message)
    end)
  end
end
