defmodule ArkTbwDelegateServer.Voters do
  alias ArkTbwDelegateServer.{Logger, Voter}

  def all(%{client: client, delegate_public_key: public_key}) do
    IO.puts("  ")
    case ArkElixir.Delegate.voters(client, public_key) do
      {:ok, voters} ->
        Enum.each(voters, &Voter.display/1)
      {:error, error} ->
        Logger.debug("ERROR FETCHING VOTERS: #{IO.inspect(error)}")
    end
  end

  def balances(opts) do
    Logger.debug(opts)
    IO.puts "You owe monies"
  end
end
