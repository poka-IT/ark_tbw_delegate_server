defmodule ArkTbwDelegateServer.MainMenu do
  require IEx

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

  defp display(opts) do
    [:green, :bright, "
    Main Menu
    ---

    1. Calculate and disburse rewards
    2. Previous disbursements
    3. Outstanding balances
    4. Voters
    5. Exit
    "]
    |> Bunt.puts

    case receive_input("Please make your selection") do
      :back -> run(opts)
      :quit -> Process.exit(self(), :normal)

      "1" -> Disbursements.run(opts)
      "2" -> Disbursements.list(opts)
      "3" -> Voters.balances(opts)
      "4" -> Voters.all(opts)
      "5" -> Process.exit(self(), :normal)

      _ -> receive_input("Invalid entry. Please make your selection (12345bq)")
    end

    IO.gets("\n\n    Press enter to return to the main menu.")
    run(opts)
  end
end
