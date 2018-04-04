defmodule ArkTbwDelegateServer.Voters do
  alias ArkTbwDelegateServer.Logger

  def all(opts) do
    Logger.debug(opts)
    IO.puts "I'm a list too!"
  end

  def balances(opts) do
    Logger.debug(opts)
    IO.puts "You owe monies"
  end
end
