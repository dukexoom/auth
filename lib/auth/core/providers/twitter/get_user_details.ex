defmodule Auth.Providers.Twitter.GetUserDetails do
  require IEx

  def call(_) do
    user = ExTwitter.verify_credentials(include_email: true)

    %Auth.Providers.User{
      email: user.email,
      full_name: user.name,
      id: user.id_str
    }
  end
end
