defmodule ArkTbwDelegateServer.Voters do
  alias ArkTbwDelegateServer.{Delegate, Logger, Voter}

  import ArkTbwDelegateServer.Utils
  import ArkTbwDelegateServer.Calculations

  def all(%{client: client, delegate_public_key: public_key}) do
    clear()
    motd()

    case ArkElixir.Delegate.voters(client, public_key) do
      {:ok, voters} ->
        Enum.each(voters, &Voter.display/1)
      {:error, error} ->
        Logger.debug("ERROR FETCHING VOTERS: #{IO.inspect(error)}")
    end
  end

  def balances(%{client: client, delegate_public_key: public_key} = opts) do
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
      Enum.each(statements, fn(statement) ->
        Bunt.puts([
          :orange,
          :bright,
          "    #{statement.ledger.account.address} has banked Ѧ " <>
          "#{Decimal.to_string(statement.amount, :normal)} from blocks " <>
          "#{statement.from} to #{statement.height}"
        ])
      end)
    else
      Bunt.puts([:orange, :bright, "    No voters found"])
    end
  end
end
