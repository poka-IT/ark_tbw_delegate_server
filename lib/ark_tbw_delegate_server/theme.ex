defmodule ArkTbwDelegateServer.Theme do
  def primary(theme \\ :dark) do
    case theme do
      :dark -> :color46
      _default -> :color202
    end
  end
end
