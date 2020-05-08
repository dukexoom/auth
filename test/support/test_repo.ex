defmodule TestRepo do
  import Ext.Utils.Map

  require IEx

  def get_or_insert!(schema, query, _), do: (schema.__struct__ ||| query) |> add_primary_key()
  def get(_, _), do: nil
  def get_by(_, _), do: nil
  def preload(_, _), do: nil
  def insert!(entity), do: entity |> add_primary_key()
  def save!(entity, params), do: (entity ||| params) |> add_primary_key()

  defp add_primary_key(%{id: nil} = entity), do: entity ||| %{id: 1}
  defp add_primary_key(%{uuid: nil} = entity), do: entity ||| %{uuid: "uniq_uuid"}
  defp add_primary_key(entity), do: entity
end
