defmodule Auth.Providers.Facebook.GetUserDetails do
  require Logger
  require IEx

  def call(%{access_token: access_token}) do
    request = %SDK.Request{
      payload: %{fields: "id,email,first_name,last_name,name,picture", type: "normal", access_token: access_token}
    }

    case Auth.SDK.Facebook.Client.me(request) do
      {:ok, fb_user} ->
        %Auth.Providers.User{
          email: fb_user["email"],
          first_name: fb_user["first_name"],
          last_name: fb_user["last_name"],
          full_name: fb_user["name"],
          id: fb_user["sub"],
          avatar: get_in(fb_user, ["picture", "data", "url"])
        }

      {:error, response} ->
        Logger.error("Error get info about player for facebook, message - #{inspect(response)}")
        nil
    end
  end
end
