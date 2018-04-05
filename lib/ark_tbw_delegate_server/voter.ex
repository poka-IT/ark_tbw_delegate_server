defmodule ArkTbwDelegateServer.Voter do
  @div 100_000_000

  def balance(%{balance: balance}) do
    balance
    |> Decimal.div(@div)
    |> Decimal.to_float
  end

  def display(voter) do
    Bunt.puts([
      :white,
      :faint,
      "    #{voter.address} - Balance: #{balance(voter)}"
    ])
  end
end
