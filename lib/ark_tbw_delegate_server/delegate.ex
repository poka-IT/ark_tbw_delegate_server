defmodule ArkTbwDelegateServer.Delegate do
  def display(%{
    delegate: %{
      address: address,
      missedblocks: missed,
      producedblocks: produced,
      productivity: productivity,
      username: name
    }
  } = opts) do
    Bunt.puts([:blue, :bright, "
    Delegate
    ---
    #{name}
    #{address}
    Blocks: #{produced} / #{missed} (#{productivity}%)
    "])

    opts
  end

  def load(
    %{client: client, delegate_public_key: public_key} = opts
  ) do
    {:ok, delegate} = ArkElixir.Delegate.delegate(client, publicKey: public_key)
    Map.put(opts, :delegate, delegate)
  end
end
