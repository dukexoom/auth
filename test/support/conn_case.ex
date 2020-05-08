defmodule Auth.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import Ext.ExUnit.Assertions
      import Mock
      import Ext.Utils.Map
      require IEx
      require Logger
    end
  end

  setup tags do
    conn = Phoenix.ConnTest.build_conn()

    cond do
      tags[:user] ->
        user = %TestUser{}

        {:ok,
         conn:
           Support.Helpers.Auth.auth_user(conn, Auth.Token.generate_and_sign!(%{"id" => user.id, "schema" => TestUser})),
         current_user: user}

      true ->
        {:ok, conn: conn}
    end
  end
end
