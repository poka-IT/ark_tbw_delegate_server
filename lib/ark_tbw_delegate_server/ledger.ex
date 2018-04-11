defmodule ArkTbwDelegateServer.Ledger do
  defstruct [:account, :transactions, :__type_index__]

  @defaults %{tranactions: [], __type_index__: %{}}
  @disbursement_regex ~r/payout to height (\d+)/

  alias ArkElixir.Models.{Account, Transaction}
  alias ArkElixir.Util.TransactionBuilder
  alias ArkTbwDelegateServer.{Ledger, Logger}

  import ArkTbwDelegateServer.Utils

  def build(%Account{} = account, client) do
    payload =
      @defaults
      |> Map.put(:account, account)
      |> add_receiving_transactions(client)
      |> add_sending_transactions(client)
      |> sort_by_time
      |> index_by_type

    struct(__MODULE__, payload)
  end

  def build(address, client) do
    {:ok, account} = ArkElixir.Account.account(client, address)
    build(account, client)
  end

  # Public API

  def balance(%Ledger{account: %Account{balance: balance}}) do
    balance |> Integer.parse |> elem(0)
  end

  def balance_at(%Ledger{transactions: transactions} = ledger, timestamp) do
    timestamp = timestamp - TransactionBuilder.ark_epoch()

    Enum.reduce(transactions, 0, fn(transaction, balance) ->
      if transaction.timestamp > timestamp do
        balance
      else
        if ledger.account.address == transaction.sender_id do
          balance - transaction.amount - transaction.fee
        else
          balance + transaction.amount
        end
      end
    end)
  end

  def delegate(%Ledger{__type_index__: %{vote: transactions}}) do
    vote =
      transactions
      |> List.first
      |> Map.get(:asset)
      |> Map.get("votes")
      |> List.first

    if String.at(vote, 0) == "+" do
      String.slice(vote, 1..-1)
    end
  end

  def delegate_at(%Ledger{__type_index__: %{vote: transactions}}, timestamp) do
    timestamp = timestamp - TransactionBuilder.ark_epoch()

    key = Enum.reduce(transactions, nil, fn(transaction, public_key) ->
      if transaction.timestamp > timestamp or !is_nil(public_key) do
        public_key
      else
        vote =
          transaction
          |> Map.get(:asset)
          |> Map.get("votes")
          |> List.first

        if String.at(vote, 0) == "+" do
          String.slice(vote, 1..-1)
        else
          :nope
        end
      end
    end)

    if key != :nope, do: key
  end

  def filter_unpaid(%Ledger{transactions: transactions}, blocks) do
    transactions
    |> Enum.reverse
    |> Enum.find(&is_disbursement?/1)
    |> case do
      nil ->
        blocks
      %{vendor_field: vendor_field} ->
        last_height =
          @disbursement_regex
          |> Regex.run(vendor_field)
          |> Enum.at(1)
          |> String.to_integer

        Enum.filter(blocks, &(&1.height > last_height))
    end
  end

  # private

  defp add_receiving_transactions(%{account: account} = payload, client) do
    params = [recipientId: account.address]
    transactions = fetch_transactions(client, params)
    transactions = Enum.map(transactions, &to_transaction/1)

    Map.put(payload, :transactions, transactions)
  end

  defp add_sending_transactions(
    %{account: account, transactions: existing} = payload,
    client
  ) do
    params = [senderId: account.address]
    transactions =
      client
      |> fetch_transactions(params)
      |> Enum.map(&to_transaction/1)

    new = Enum.reject(transactions, &Enum.member?(existing, &1))

    Map.put(payload, :transactions, new ++ existing)
  end

  defp add_to_index(%{type: 0} = transaction, index) do
    Map.put(index, :transfer, [transaction] ++ index.transfer)
  end

  defp add_to_index(%{type: 1} = transaction, index) do
    Map.put(index, :second_signature, [transaction] ++ index.second_signature)
  end

  defp add_to_index(%{type: 2} = transaction, index) do
    Map.put(index, :delegate, [transaction] ++ index.delegate)
  end

  defp add_to_index(%{type: 3} = transaction, index) do
    Map.put(index, :vote, [transaction] ++ index.vote)
  end

  defp add_to_index(%{type: 4} = transaction, index) do
    Map.put(index, :multisignature, [transaction] ++ index.multisignature)
  end

  defp fetch_transactions(client, params, transactions \\ []) do
    offset = Enum.count(transactions)
    actual_params = params ++ [limit: 50, offset: offset]

    new_transactions =
      client
      |> ArkElixir.Transaction.transactions(actual_params)
      |> case do
        {:ok, new_transactions} ->
          new_transactions
        {:error, :socket_closed_remotely} ->
          Logger.warn("Retrying in 1 second...")
          Process.sleep(1000)
          {:ok, new_transactions} =
            ArkElixir.Transaction.transactions(client, actual_params)
          new_transactions
      end
      |> Enum.map(fn(%{id: id}) ->
        case ArkElixir.Transaction.transaction(client, id) do
          {:ok, transaction} ->
            transaction
          {:error, :socket_closed_remotely} ->
            Logger.warn("Retrying in 1 second...")
            Process.sleep(1000)
            {:ok, transaction} = ArkElixir.Transaction.transaction(client, id)
            transaction
        end
      end)

    if Enum.count(new_transactions) < 50 do
      transactions ++ new_transactions
    else
      fetch_transactions(client, params, transactions ++ new_transactions)
    end
  end

  defp index_by_type(%{transactions: transactions} = payload) do
    index = %{
      delegate: [],
      multisignature: [],
      second_signature: [],
      transfer: [],
      vote: []
    }

    Map.put(
      payload,
      :__type_index__,
      Enum.reduce(transactions, index, &add_to_index/2)
    )
  end

  defp is_disbursement?(%Transaction{vendor_field: vendor_field})
  when is_bitstring(vendor_field) do
    Regex.match?(@disbursement_regex, vendor_field)
  end

  defp is_disbursement?(_) do
    false
  end

  defp sort_by_time(%{transactions: transactions} = payload) do
    sorted = Enum.sort_by(transactions, &(&1.timestamp))
    Map.put(payload, :transactions, sorted)
  end

  defp to_transaction(%Transaction{} = transaction) do
    transaction
  end

  defp to_transaction(transaction) do
    struct(Transaction, atomize_keys(transaction))
  end
end
