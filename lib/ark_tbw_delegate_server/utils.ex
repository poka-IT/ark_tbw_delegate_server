defmodule ArkTbwDelegateServer.Utils do
  @default_prompt "Please enter a value, q to quit or b to to back (qb)"

  def clear do
    IO.ANSI.clear() |> IO.puts
  end

  def motd do
    [:red, :bright, "
    WXxd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dxXM
    MMMMMMMMMMMMMMMMMNx", :white, ";;", :red, "xNMMMMMMMMMMMMMMMMM
    MMMMMMMMMMMMMMMMXo", :white, "'..,", :red, "oXWMMMMMMMMMMMMMMM
    MMMMMMMMMMMMMMW0c", :white, "'....'", :red, "l0WMMMMMMMMMMMMMM
    MMMMMMMMMMMMMWO", :white, ":.......'", :red, ":OWMMMMMMMMMMMMM
    MMMMMMMMMMMMNx", :white, ",..........;", :red, "xNMMMMMMMMMMMM
    MMMMMMMMMMWXo", :white, "'....:", :red, "ll", :white, ":'...,",
    :red, "oXMMMMMMMMMMM
    MMMMMMMMMW0c", :white, "'...;", :red, "xXWWXx", :white, ":'..'",
    :red, "l0WMMMMMMMMM
    MMMMMMMMWO", :white, ":...;", :red, "dKWNXXNWXx", :white, ":'..:",
    :red, "OWMMMMMMMM
    MMMMMMMNx", :white, ";..;", :red, "dKWN0l", :white, ";;", :red, "l0NWKd",
    :white, ";'.;", :red, "xNMMMMMMM
    MMMMMWXo", :white, ",.;", :red, "dKWMWXkdoooxXWMWKd", :white, ";.'",
    :red, "oXWMMMMM
    MMMMW0c", :white, "';", :red, "oKWWKOOOOkkkkkOOOKWWKo", :white, ",'",
    :red, "c0WMMMM
    MMMWO", :white, ":;", :red, "o0WWKo", :white, ";'..........';", :red,
    "dKWW0o", :white, ";:", :red, "ONMMM
    MMNx", :white, ":", :red, "o0WMMN;", :white, "................", :red,
    ";NMMW0o", :white, ":", :red, "xNMM
    WXxd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dxXM

    ", :white, :faint, "ARK True Block Weight Delegate Manager
    Sponsored By: https://arkcommunity.fund
    Built By: arkoar.group delegate
    "]
    |> Bunt.puts
  end

  def receive_input(message \\ "") do
    input = "    #{message}: " |> IO.gets |> String.trim

    case input do
      "" ->
        receive_input(@default_prompt)
      "b" ->
        :back
      "q" ->
        :quit
      value ->
        value
    end
  end
end
