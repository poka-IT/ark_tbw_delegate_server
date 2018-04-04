defmodule ArkTbwDelegateServer.MainMenu do
  @menu """
Main Menu
---

1. Calculate and disburse rewards
2. Previous disbursements
3. Outstanding balances
4. Voters
5. Exit
"""

  require IEx

  import ArkTbwDelegateServer.Utils

  alias ArkTbwDelegateServer.{Disbursements, Voters}

  def run(opts) do
    display(opts)
  end

  # private

  defp display(opts) do
    [@menu, :color46]
    |> Bunt.puts

    case receive_input("Please make your selection") do
      :back -> display(opts)
      :quit -> Process.exit(self(), :normal)

      "1" -> Disbursements.run(opts)
      "2" -> Disbursements.list(opts)
      "3" -> Voters.balances(opts)
      "4" -> Voters.all(opts)
      "5" -> Process.exit(self(), :normal)

      _ -> receive_input("Invalid entry. Please make your selection (12345bq)")
    end

    IO.gets("\n\nPress enter to return to the main menu.")
    clear()
    run(opts)
  end
end
