defmodule ArkTbwDelegateServer.Audit do
  def new do
    now = DateTime.utc_now |> DateTime.to_unix(:millisecond)
    path = "#{dir()}/#{now}.audit.log"
    {:ok, file} = File.open(path, [:append])
    file
  end

  def write(file, value) when is_bitstring(value) do
    IO.binwrite(file, "#{value}\n")
  end

  def write(file, %{__struct__: _module} = struct) do
    write(file, Map.from_struct(struct))
  end

  def write(file, value) do
    write(file, inspect(value, pretty: true, width: 100))
  end

  # private

  def dir do
    home = System.user_home()
    path = "#{home}/.atbw/audit"
    File.mkdir_p!(path)
    path
  end
end
