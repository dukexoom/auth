defmodule Auth.AddRestorePasswordDataTest do
  use Auth.ConnCase

  test "call" do
    with_mocks [
      {DateTime, [:passthrough], utc_now: fn -> ~U[2019-09-19 13:00:00.000000Z] end},
      {Ext.Utils.Repo, [:passthrough], generate_uniq_hash: fn _, _, _, _ -> "uniq_hash" end}
    ] do
      user = Auth.AddRestorePasswordData.call(%TestUser{}, TestRepo)

      assert user.restore_hash == "uniq_hash"
      assert user.restore_expire == ~U[2019-09-19 14:00:00.000000Z]
    end
  end
end
