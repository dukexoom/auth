defmodule Auth.Providers.Google.GetUserDetails do
  require IEx

  def call(%{id_token: token}) do
    {:ok, google_user} = Joken.peek_claims(token)

    %Auth.Providers.User{
      email: google_user["email"],
      first_name: google_user["given_name"],
      last_name: google_user["family_name"],
      full_name: google_user["name"],
      id: google_user["sub"],
      avatar: google_user["picture"]
    }
  end
end
