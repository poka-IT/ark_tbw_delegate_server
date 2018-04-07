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

  def forged(%{client: client, delegate: delegate}) do
    cache_path = ".#{delegate.address}.cache"

    blocks =
      case File.read(cache_path) do
        {:ok, ""} -> []
        {:ok, json} -> Jason.decode!(json)
        {:error, _} -> []
      end

    blocks = fetch_blocks(client, delegate.public_key, blocks)

    {:ok, cache} = File.open(cache_path, [:write])
    IO.write(cache, Jason.encode!(blocks))

    blocks
  end

  def load(
    %{client: client, delegate_public_key: public_key} = opts
  ) do
    {:ok, delegate} = ArkElixir.Delegate.delegate(client, publicKey: public_key)
    Map.put(opts, :delegate, delegate)
  end

  # private

  defp fetch_blocks(client, public_key, blocks) do
    offset = Enum.count(blocks)

    {:ok, new_blocks} = ArkElixir.Block.blocks(
      client,
      generatorPublicKey: public_key,
      limit: 50,
      offset: offset
    )

    if Enum.count(new_blocks) < 50 do
      blocks ++ new_blocks
    else
      fetch_blocks(client, public_key, blocks ++ new_blocks)
    end
  end
end
