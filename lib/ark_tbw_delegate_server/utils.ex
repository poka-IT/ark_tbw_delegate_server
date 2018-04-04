defmodule ArkTbwDelegateServer.Utils do
  @default_prompt "Please enter a value, q to quit or b to to back (qb)"

  def clear do
    IO.ANSI.clear() |> IO.puts
  end

  def receive_input(message \\ "") do
    input = IO.gets("#{message}: ") |> String.trim |> String.downcase

    case input do
      "" ->
        IO.write @default_prompt
        receive_input()
      "b" ->
        :back
      "q" ->
        :quit
      value ->
        value
    end
  end
end
