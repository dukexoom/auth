defmodule Auth.SDK.Google.Config do
  def data,
    do: %{
      base_url: "https://www.googleapis.com",
      sdk_name: "Google Auth",
      endpoints: %{
        certs: %{
          type: :get,
          url: "/oauth2/v3/certs"
        }
      }
    }
end
