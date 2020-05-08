defmodule Auth.RestorePasswordFormTest do
  use Auth.ConnCase

  setup_with_mocks([{DateTime, [:passthrough], [utc_now: fn -> ~U[2019-09-19 13:00:00.000000Z] end]}]) do
    %{entity: %{restore_hash: "123qweasdzxc", password: "123qwe", password_confirmation: "123qwe"}}
  end

  describe "invalid restored data" do
    test "user not exist", %{entity: entity} do
      %{valid?: valid?, changes: %{context: %{user: user}}, errors: [{:password, {error, _}} | _]} =
        Auth.RestorePasswordForm.call(entity, %{repo: TestRepo, schemas: %{user: TestUser}})

      assert valid? == false
      assert error == "Invalid restore hash"
      refute user
    end

    test "expired restore_hash", %{entity: entity} do
      with_mocks [
        {TestRepo, [:passthrough],
         [
           get_by: fn _, _ ->
             %TestUser{id: 1, restore_hash: entity.restore_hash, restore_expire: ~U[2019-09-19 12:59:00.000000Z]}
           end
         ]}
      ] do
        %{valid?: valid?, errors: [{:password, {error, _}} | _]} =
          Auth.RestorePasswordForm.call(entity, %{repo: TestRepo, schemas: %{user: TestUser}})

        assert valid? == false
        assert error == "Invalid restore hash"
      end
    end
  end

  test "valid restored data", %{entity: entity} do
    with_mocks [
      {TestRepo, [:passthrough],
       [
         get_by: fn _, _ ->
           %TestUser{id: 1, restore_hash: entity.restore_hash, restore_expire: ~U[2019-09-19 13:59:00.000000Z]}
         end
       ]}
    ] do
      form = Auth.RestorePasswordForm.call(entity, %{repo: TestRepo, schemas: %{user: TestUser}})
      assert form.valid? == true
    end
  end
end
