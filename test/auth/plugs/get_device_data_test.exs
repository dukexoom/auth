defmodule Auth.Plugs.GetDeviceDataTest do
  use Auth.ConnCase
  @moduletag :user

  setup do
    test_conn = build_conn()
    %{test_conn: test_conn}
  end

  test ".init" do
    assert Auth.Plugs.GetDeviceData.init(opts: "opts") == [opts: "opts"]
  end

  describe ".call" do
    test "conn has no context", %{test_conn: test_conn} do
      conn = Auth.Plugs.GetDeviceData.call(test_conn, %{})

      assert conn.private[:absinthe][:context] == %{
               device_data: %{
                 browser: Browser.name(test_conn),
                 ip: test_conn.remote_ip,
                 platform: Browser.full_platform_name(conn)
               }
             }
    end

    test "conn with context", %{test_conn: test_conn} do
      conn = Auth.Plugs.GetDeviceData.call(put_private(test_conn, :absinthe, %{context: %{test: "value"}}), %{})

      assert conn.private[:absinthe][:context] == %{
               device_data: %{
                 browser: Browser.name(test_conn),
                 ip: test_conn.remote_ip,
                 platform: Browser.full_platform_name(conn)
               },
               test: "value"
             }
    end
  end
end
