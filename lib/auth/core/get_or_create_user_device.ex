defmodule Auth.GetOrCreateUserDevice do
  @moduledoc false

  import Ext.Utils.Map

  def call(%{schemas: %{user: user_schema, device: device_schema}} = params, user_id, device_uuid, device_data) do
    user_assoc = Ext.Ecto.Schema.get_schema_assoc(device_schema, user_schema)

    get_or_create_device(
      params,
      user_id,
      user_assoc,
      device_uuid,
      prepare_data(user_id, user_assoc, device_data)
    )
  end

  defp get_or_create_device(%{repo: repo, schemas: %{device: device_schema}}, _user_id, _user_assoc, nil, data),
    do: repo.save!(device_schema.__struct__, data)

  defp get_or_create_device(%{repo: repo, schemas: %{device: device_schema}}, user_id, user_assoc, device_uuid, data),
    do: repo.get_or_insert!(device_schema, %{"#{user_assoc}_id": user_id, uuid: device_uuid}, data)

  defp prepare_data(user_id, user_assoc, nil), do: prepare_data(user_id, user_assoc, %{})

  defp prepare_data(user_id, user_assoc, device_data) do
    %{"#{user_assoc}_id": user_id, uuid: nil} ||| device_data
  end
end
