defmodule Auth.Providers.Facebook.DecodeUserToken do
  require Logger
  require IEx

  def call(user_token) do
    app_token = Auth.Providers.Facebook.GetAppAccessToken.call()

    request = %SDK.Request{
      payload: %{
        input_token: user_token,
        access_token: app_token
      }
    }

    case Auth.SDK.Facebook.Client.debug_user_token(request) do
      {:ok, %{"data" => data}} ->
        data

      {:error, response} ->
        Logger.error("Error when try to decode user access token, message - #{inspect(response)}")
        nil
    end
  end
end
