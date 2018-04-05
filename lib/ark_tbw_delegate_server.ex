defmodule ArkTbwDelegateServer do
  @moduledoc """
  Documentation for ArkTbwDelegateServer.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ArkTbwDelegateServer.hello
      :world

  """
  def run do
    ArkTbwDelegateServer.CLI.main()
  end
end
