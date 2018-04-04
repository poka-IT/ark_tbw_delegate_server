defmodule ArkTbwDelegateServer.Logger do
  require Logger

  # Contextual

  def rescued_error(err, stacktrace) do
    :error |> Exception.format(err, stacktrace) |> error
    err
  end

  # Generic

  def debug(value) when is_bitstring(value) do
    Logger.debug(value)
    value
  end

  def debug(value) do
    value |> pp |> debug
    value
  end

  def error(value) when is_bitstring(value) do
    Logger.error(value)
    value
  end

  def error(value) do
    value |> pp |> error
    value
  end

  def info(value) when is_bitstring(value) do
    Logger.info(value)
    value
  end

  def info(value) do
    value |> pp |> info
    value
  end

  def log(:debug, value) do
    debug(value)
  end

  def log(:error, value) do
    error(value)
  end

  def log(:info, value) do
    info(value)
  end

  def log(:warn, value) do
    warn(value)
  end

  def warn(value) when is_bitstring(value) do
    Logger.warn(value)
    value
  end

  def warn(value) do
    value |> pp |> warn
    value
  end

  # private

  defp pp(value) do
    inspect(value, pretty: true, width: 100)
  end
end
