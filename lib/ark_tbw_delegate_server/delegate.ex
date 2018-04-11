defmodule ArkTbwDelegateServer.Delegate do
  alias ArkElixir.Models.Block
  alias ArkTbwDelegateServer.Cache

  import ArkTbwDelegateServer.Utils

  @limit 100

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

  def forged(%{client: client, delegate: delegate} = opts) do
    cache_path = Cache.path(delegate.address, :forged)

    blocks = Cache.load(cache_path)

    cached_height =
      if(Enum.count(blocks) > 0) do
        blocks |> List.first |> Map.get("height")
      else
        0
      end

    blocks =
      client
      |> fetch_blocks(delegate.public_key, blocks, cached_height)
      |> Enum.map(&to_block/1)
      |> Enum.filter(&(&1.height > opts.initial_block_height))
      |> Enum.uniq_by(&(&1.height))
      |> Enum.sort_by(&(&1.height))
      |> Enum.reverse

    Cache.dump(cache_path, blocks)

    blocks
  end

  def load(
    %{client: client, delegate_public_key: public_key} = opts
  ) do
    {:ok, delegate} = ArkElixir.Delegate.delegate(client, publicKey: public_key)
    Map.put(opts, :delegate, delegate)
  end

  # private

  defp fetch_blocks(client, public_key, blocks, cached_height, offset \\ 0) do
    {:ok, new_blocks} = ArkElixir.Block.blocks(
      client,
      generatorPublicKey: public_key,
      limit: @limit,
      offset: offset,
      orderBy: "height:desc"
    )

    if Enum.count(new_blocks) > 0 do
      new_height = new_blocks |> List.last |> Map.get(:height)

      if new_height <= cached_height do
        new_blocks =
          Enum.filter(new_blocks, &(Map.get(&1, :height) > cached_height))
        new_blocks ++ blocks
      else
        blocks = new_blocks ++ blocks
        fetch_blocks(client, public_key, blocks, cached_height, offset + @limit)
      end
    else
      blocks
    end
  end

  defp to_block(%Block{} = block) do
    block
  end

  defp to_block(block) do
    struct(Block, atomize_keys(block))
  end
end
