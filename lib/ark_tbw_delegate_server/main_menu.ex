defmodule ArkTbwDelegateServer.MainMenu do
  @confirm_clear "Are you sure you want to clear the cache and config? (YN)"

  import ArkTbwDelegateServer.Utils

  alias ArkTbwDelegateServer.{Delegate, Disbursements, Voters}

  def run(opts) do
    clear()
    motd()

    opts
    |> Delegate.load
    |> Delegate.display
    |> display

    opts
  end

  # private

  defp clear_cache do
    clear()

    case receive_input(@confirm_clear) do
      "q" ->
        Process.exit(self(), :normal)
      "Y" ->
        Bunt.puts([:orange, :bright, "\n    Removing config.json..."])
        File.rm!("./config.json")
        Bunt.puts([:orange, :bright, "    Removing .cache directory...\n"])
        File.rm_rf!("./.cache")
        Bunt.puts([:green, :bright, "    Done. Please restart to continue.\n"])
        Process.exit(self(), :normal)
      _ ->
        IO.puts("\n    Cancelled.\n")
    end
  end

  defp display(opts) do
    [:green, :bright, "
    Main Menu
    ---

    1. Calculate and disburse rewards
    2. Previous disbursements
    3. Outstanding balances
    4. Voters
    5. Exit

    0. Clear all cached data and start fresh
    "]
    |> Bunt.puts

    case receive_input("Please make your selection") do
      :back -> run(opts)
      :quit -> Process.exit(self(), :normal)

      "0" -> clear_cache()
      "1" -> Disbursements.run(opts)
      "2" -> Disbursements.list(opts)
      "3" -> Voters.balances(opts)
      "4" -> Voters.all(opts)
      "5" -> Process.exit(self(), :normal)

      _ -> receive_input("Invalid entry. Please make your selection (012345bq)")
    end

    IO.gets("\n\n    Press enter to return to the main menu.")
    run(opts)
  end
end
