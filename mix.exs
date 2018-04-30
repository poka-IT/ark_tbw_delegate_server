defmodule ArkTbwDelegateServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :ark_tbw_delegate_server,
      version: "1.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: ArkTbwDelegateServer.CLI]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:bunt, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ark_elixir, git: "https://github.com/arkoar-group/ARK-Elixir", branch: "refactor/tesla"},
      {:bunt, "~> 0.1"},
      {:decimal, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:progress_bar, "> 0.0.0"}
    ]
  end
end
