defmodule Support.Helpers.Auth do
  @moduledoc false
  def auth_user(conn, token), do: Plug.Conn.put_req_header(conn, "authorization", "#{token}")
end
