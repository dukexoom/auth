defmodule Auth.Plugs.Authenticate do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  require IEx

  def init(opts) do
    opts
  end

  # for opening /graphiql
  def call(%{params: params} = conn, _opts) when params == %{}, do: conn

  def call(conn, opts) do
    if Ext.GQL.AllQueriesArePresented.call(conn.params["query"], opts[:exclude]) do
      conn
    else
      case build_context(conn, opts[:repos]) do
        {:ok, context} ->
          put_private(conn, :absinthe, %{context: context})

        {:error, :invalid_access_token} ->
          conn
          |> send_resp(401, "invalid_access_token")
          |> halt()

        {:error, reason} ->
          conn
          |> send_resp(403, reason)
          |> halt()
      end
    end
  end

  defp build_context(conn, repos) do
    with [access_key] <- get_req_header(conn, "authorization"),
         {:ok, current_user} <- authorize(access_key, repos) do
      {:ok, %{current_user: current_user}}
    else
      [] -> {:error, "Fill in header 'Authorization'"}
      error -> error
    end
  end

  defp authorize(access_token, repos) do
    case Auth.Token.verify_and_validate(access_token) do
      {:ok, %{"id" => id, "schema" => schema}} ->
        schema = Ext.Utils.Base.to_existing_atom(schema)
        {:ok, repos[schema].get(schema, id)}

      {:error, _} ->
        {:error, :invalid_access_token}
    end
  end
end
