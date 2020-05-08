defmodule Auth.SignInFormTest do
  use Auth.ConnCase

  describe ".validate_user" do
    test "user not exists" do
      %{valid?: valid?, errors: [email: {error, _}]} =
        Auth.SignInForm.call(%{email: "not_exist@email.com", password: "123456"}, %{repo: TestRepo, schemas: %{user: TestUser}})

      refute valid?
      assert error == "invalid_email"
    end

    test "invalid password" do
      with_mocks [
        {TestRepo, [:passthrough],
         [get_by: fn _, _ -> %TestUser{id: 1, email: "test@email.com", encrypted_password: "not_encrypted"} end]}
      ] do
        %{valid?: valid?, errors: [password: {error, _}]} =
          Auth.SignInForm.call(%{email: "test@email.com", password: "invalid"}, %{repo: TestRepo, schemas: %{user: TestUser}})

        refute valid?
        assert error == "invalid_password"
      end
    end

    test "valid" do
      with_mocks [
        {TestRepo, [:passthrough],
         [
           get_by: fn _, _ ->
             %TestUser{id: 1, email: "test@email.com", encrypted_password: Bcrypt.hash_pwd_salt("123qwe")}
           end
         ]}
      ] do
        %{valid?: valid?, changes: %{context: context}} =
          Auth.SignInForm.call(%{email: "test@email.com", password: "123qwe"}, %{repo: TestRepo, schemas: %{user: TestUser}})

        assert valid?
        assert context.user.email == "test@email.com"
      end
    end
  end
end
