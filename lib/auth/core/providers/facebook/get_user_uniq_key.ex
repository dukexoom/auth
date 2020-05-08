defmodule Auth.Providers.Facebook.GetUserUniqKey do
  require IEx

  def call(%{access_token: user_token} = auth_response) do
    user_token
    |> Auth.Providers.Facebook.DecodeUserToken.call()
    |> Ext.Utils.Base.to_atom()
    |> check_valid?()
    |> check_app_id()
    |> check_user_id(auth_response)
    |> get_in([:user_id])
  end

  defp check_valid?(%{is_valid: true} = token_data), do: token_data
  defp check_valid?(%{is_valid: false, errors: %{message: message}}), do: raise(message)

  defp check_app_id(%{app_id: app_id} = token_data) do
    cond do
      app_id == Application.get_env(:auth, :facebook_client_id) -> token_data
      true -> raise("Invalid facebook app_id")
    end
  end

  defp check_user_id(%{user_id: decoded_user_id}, %{user_id: user_id}) when decoded_user_id != user_id,
    do: raise("Invalid facebook user_id")

  defp check_user_id(token_data, _), do: token_data
end
