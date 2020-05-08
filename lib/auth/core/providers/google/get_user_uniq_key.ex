defmodule Auth.Providers.Google.GetUserUniqKey do
  @iss_domains ["accounts.google.com", "https://accounts.google.com"]

  def call(%{id_token: token}) do
    {:ok, %{"keys" => keys}} = Auth.SDK.Google.Client.certs()

    {:ok, %{"kid" => kid}} = Joken.peek_header(token)

    key = Enum.find(keys, &(&1["kid"] == kid))

    signer = Joken.Signer.create("RS256", key)

    case Joken.verify(token, signer) do
      {:ok, google_user} ->
        google_user
        |> Ext.Utils.Base.to_atom()
        |> check_aud()
        |> check_iss_domain()
        |> check_exp_time()
        |> get_in([:sub])

      _ ->
        raise("Google id_token is not verified")
    end
  end

  defp check_aud(%{aud: aud} = google_user) do
    cond do
      aud == Application.get_env(:auth, :google_client_id) -> google_user
      true -> raise("Invalid google aud")
    end
  end

  defp check_iss_domain(%{iss: iss} = google_user) when iss in @iss_domains, do: google_user

  defp check_iss_domain(_), do: raise("Invalid google iss domain")

  defp check_exp_time(%{exp: exp} = google_user) do
    {:ok, exp_time} = DateTime.from_unix(exp)

    case Timex.compare(DateTime.utc_now(), exp_time) do
      1 -> raise("The expiry time (exp) of the ID token passed")
      _ -> google_user
    end
  end
end
