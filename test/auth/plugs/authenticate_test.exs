defmodule Auth.Plugs.AuthenticateTest do
  use Auth.ConnCase
  @moduletag :user

  setup do
    conn_params = %{
      "query" => "query {\n  genders {\n    id\n   }\n}",
      "variables" => nil
    }

    test_conn = Map.merge(build_conn(), %{params: conn_params})
    %{test_conn: test_conn, conn_params: conn_params}
  end

  test ".init" do
    assert Auth.Plugs.Authenticate.init(opts: "opts") == [opts: "opts"]
  end

  describe ".call" do
    test "/graphiql" do
      conn = %{params: %{}}
      assert Auth.Plugs.Authenticate.call(conn, []) == conn
    end

    test "excluded query", %{test_conn: test_conn} do
      assert Auth.Plugs.Authenticate.call(test_conn, exclude: [:genders]) == test_conn
    end

    test "without authorization header", %{test_conn: test_conn} do
      conn = Auth.Plugs.Authenticate.call(test_conn, [])
      assert conn.status == 403
      assert conn.halted
      assert conn.resp_body == "Fill in header 'Authorization'"
    end

    test "without valid authorization header", %{conn: conn, conn_params: conn_params, current_user: current_user} do
      with_mocks [{TestRepo, [:passthrough], [get: fn _, _ -> current_user end]}] do
        %{private: %{absinthe: %{context: %{current_user: conn_user}}}} =
          Auth.Plugs.Authenticate.call(Map.merge(conn, %{params: conn_params}), repos: %{TestUser => TestRepo})

        assert conn_user == current_user
      end
    end

    test "without invalid authorization header", %{conn: conn, conn_params: conn_params} do
      resp_conn =
        Auth.Plugs.Authenticate.call(
          Map.merge(conn, %{params: conn_params, req_headers: [{"authorization", "invalid_access_key"}]}),
          []
        )

      assert resp_conn.status == 401
      assert resp_conn.halted
      assert resp_conn.resp_body == "invalid_access_token"
    end
  end
end
