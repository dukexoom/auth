defmodule Auth.GetOrCreateUserDeviceTest do
  use Auth.ConnCase

  setup_with_mocks([
    {TestRepo, [:passthrough],
     [
       save!: fn struct, params -> struct ||| params ||| %{uuid: "uniq_hash"} end,
       get_or_insert!: fn schema, query, params ->
         schema.__struct__ ||| %{id: 1} ||| query ||| params ||| %{uuid: "device_uuid"}
       end
     ]},
    {Ext.Utils.Repo, [:passthrough], generate_uniq_hash: fn _, _, _, _ -> "uniq_hash" end}
  ]) do
    :ok
  end

  describe ".call" do
    test "with device_uuid in args" do
      assert %TestAuthDevice{test_user_id: 3, browser: "Browser", platform: "Platform", uuid: "device_uuid"} =
               Auth.GetOrCreateUserDevice.call(
                 %{repo: TestRepo, schemas: %{user: TestUser, device: TestAuthDevice}},
                 3,
                 "device_uuid",
                 %{browser: "Browser", platform: "Platform"}
               )
    end

    test "without device_uuid in args" do
      assert %TestAuthDevice{test_user_id: 3, browser: "Browser", platform: "Platform", uuid: "uniq_hash"} =
               Auth.GetOrCreateUserDevice.call(
                 %{repo: TestRepo, schemas: %{user: TestUser, device: TestAuthDevice}},
                 3,
                 nil,
                 %{browser: "Browser", platform: "Platform"}
               )
    end
  end
end
