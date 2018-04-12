defmodule ArkTbwDelegateServer.Utils do
  import IO.ANSI, only: [blue: 0, bright: 0, green: 0, faint: 0]

  @default_prompt "Please enter a value, q to quit or b to to back (qb)"

  def atomize_key({key, value}, acc) when is_atom(key) do
    Map.put(acc, key, value)
  end

  def atomize_key({key, value}, acc) when is_bitstring(key) do
    Map.put(acc, String.to_atom(key), value)
  end

  def atomize_keys(map) do
    Enum.reduce(map, %{}, &atomize_key/2)
  end

  def clear do
    IO.ANSI.clear() |> IO.puts
  end

  def loading(
    loading_message \\ "Loading",
    loaded_message \\ "Loaded",
    loading_color \\ blue(),
    loaded_color \\ blue(),
    bright \\ true,
    action
  ) do
    text =
      if bright do
        [bright(), loading_color, "#{loading_message}..."]
      else
        [faint(), loading_color, "#{loading_message}..."]
      end

    done =
      if bright do
        [green(), bright(), "    ✓", loaded_color, " #{loaded_message}"]
      else
        [green(), faint(), "    ✓", loaded_color, " #{loaded_message}"]
      end

    format = [
      frames: ["    ⠋", "    ⠙", "    ⠹", "    ⠸", "    ⠼", "    ⠴", "    ⠦", "    ⠧", "    ⠇", "    ⠏"],
      text: text,
      done: done,
      spinner_color: green(),
      interval: 100,  # milliseconds between frames
    ]

    ProgressBar.render_spinner(format, action)
  end

  def motd do
    Bunt.puts([:red, :bright, "
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

    ", :white, :faint, "ARK True Block Weight Delegate Server
    Sponsored By: https://arkcommunity.fund
    Built By: arkoar.group delegate
    "])
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

  def shutdown do
    Process.exit(self(), :normal)
  end
end
