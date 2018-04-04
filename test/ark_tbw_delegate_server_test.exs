defmodule ArkTbwDelegateServerTest do
  use ExUnit.Case
  doctest ArkTbwDelegateServer

  test "greets the world" do
    assert ArkTbwDelegateServer.hello() == :world
  end
end
