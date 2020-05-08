defmodule Auth.SDK.Facebook.Config do
  def data,
    do: %{
      base_url: "https://graph.facebook.com",
      sdk_name: "FB",
      endpoints: %{
        me: %{
          type: :get,
          url: "/me"
        },
        app_token: %{
          type: :get,
          url: "/oauth/access_token"
        },
        debug_user_token: %{
          type: :get,
          url: "/debug_token"
        }
      }
    }
end
