defmodule ArkTbwDelegateServer.Disbursements do
  alias ArkTbwDelegateServer.{Delegate, Logger}

  def list(opts) do
    Logger.debug(opts)
    IO.puts "I'm a list!"
  end

  def run(opts) do
    Logger.debug(opts.delegate)
    IO.puts "I'm disbursing shit now..."
    Delegate.forged(opts)
    IO.puts "done!"
  end
end
