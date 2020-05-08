defmodule Auth.Plugs.GetDeviceData do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  import Ext.Utils.Map
  require IEx

  def init(opts) do
    opts
  end

  def call(conn, _opts),
    do: put_private(conn, :absinthe, %{context: get_context(conn) ||| %{device_data: get_devaice_data(conn)}})

  defp get_context(conn), do: conn.private[:absinthe][:context] || %{}

  defp get_devaice_data(conn),
    do: %{
      browser: Browser.name(conn),
      platform: Browser.full_platform_name(conn),
      ip: conn.remote_ip
    }
end
