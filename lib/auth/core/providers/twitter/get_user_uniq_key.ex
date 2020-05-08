defmodule Auth.Providers.Twitter.GetUserUniqKey do
  require IEx

  def call(%{oauth_token: oauth_token, oauth_verifier: oauth_verifier}) do
    {:ok, %{user_id: user_id, oauth_token: oauth_token, oauth_token_secret: oauth_token_secret}} =
      ExTwitter.access_token(oauth_verifier, oauth_token)

    ExTwitter.configure(
      consumer_key: Application.get_env(:auth, :twitter_consumer_key),
      consumer_secret: Application.get_env(:auth, :twitter_consumer_secret),
      access_token: oauth_token,
      access_token_secret: oauth_token_secret
    )

    user_id
  end
end
