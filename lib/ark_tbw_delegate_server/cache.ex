defmodule ArkTbwDelegateServer.Cache do
  def dump(path, collection) do
    {:ok, file} = File.open(path, [:write])
    IO.binwrite(file, Jason.encode!(collection))
  end

  def load(path) do
    case File.read(path) do
      {:ok, ""} -> []
      {:ok, json} -> Jason.decode!(json)
      {:error, _} -> []
    end
  end

  def path(address, type) do
    "#{dir()}/#{address}.#{type}"
  end

  # private

  def dir do
    home = System.user_home()
    path = "#{home}/.atbw/cache"
    File.mkdir_p!(path)
    path
  end
end
