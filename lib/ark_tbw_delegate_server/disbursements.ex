defmodule ArkTbwDelegateServer.Disbursements do
  alias ArkTbwDelegateServer.Logger

  def list(opts) do
    Logger.debug(opts)
    IO.puts "I'm a list!"
  end

  def run(opts) do
    Logger.debug(opts)
    IO.puts "I'm disbursing shit now..."
  end
end
