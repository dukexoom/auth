defmodule Auth.Providers.SignIn do
  require IEx

  def call(user, authorization, required_fields) do
    case required_fields -- (user |> Map.from_struct() |> Enum.filter(fn {_, v} -> v != nil end) |> Keyword.keys()) do
      [] ->
        {:ok, user}

      missing_fields ->
        {:error,
         {:authorization_not_complete,
          %{
            missing_fields: missing_fields,
            oauth_data: authorization |> Map.from_struct() |> Map.take([:uid, :provider])
          }}}
    end
  end
end
