defmodule Auth.GenerateJWTData do
  @moduledoc false

  def call(user, repo, device) do
    %{refresh_token: refresh_token, uuid: device_uuid} =
      repo.save!(device, %{
        refresh_token: Ext.Utils.Repo.generate_uniq_hash(device.__struct__, :refresh_token, 30, repo)
      })

    access_token = Auth.Token.generate_and_sign!(%{"id" => user.id, "schema" => user.__struct__})

    %{access_token: access_token, refresh_token: refresh_token, device_uuid: device_uuid, current_user: user}
  end
end
