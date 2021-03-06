defmodule Auth.Plugs.Authenticate do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  require IEx

  def init(opts), do: opts

  # for opening /graphiql
  def call(%{params: params} = conn, _opts) when params == %{}, do: conn

  def call(conn, opts) do
    if Ext.GQL.AllQueriesArePresented.call(conn.params["query"], opts[:exclude]) do
      conn
    else
      conn
      |> build_context(opts[:repos])
      |> reply(conn, opts[:accept_no_auth])
    end
  end

  defp reply({:ok, context}, conn, _), do: put_private(conn, :absinthe, %{context: context})
  defp reply({:error, :invalid_access_token}, conn, _), do: conn |> send_resp(401, "invalid_access_token") |> halt()

  defp reply({:error, :no_auth}, conn, accepted_queries) do
    if Ext.GQL.AllQueriesArePresented.call(conn.params["query"], accepted_queries) do
      conn
    else
      conn
      |> send_resp(403, "Fill in header 'Authorization'")
      |> halt()
    end
  end

  defp reply({:error, reason}, conn, _), do: conn |> send_resp(403, reason) |> halt()

  defp build_context(conn, repos) do
    with [access_key] <- get_req_header(conn, "authorization"),
         {:ok, current_user} <- authorize(access_key, repos) do
      {:ok, %{current_user: current_user}}
    else
      [] -> {:error, :no_auth}
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
