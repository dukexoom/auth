defmodule Auth.ForgotPasswordFormTest do
  use Auth.ConnCase

  test "user not exist" do
    %{valid?: valid?, changes: %{context: %{user: user}}, errors: [{:email, {error, _}} | _]} =
      Auth.ForgotPasswordForm.call(%{email: "test@email.com"}, %{repo: TestRepo, schema: TestUser})

    refute valid?
    assert error == "Email test@email.com not found"
    refute user
  end

  test "valid data" do
    with_mocks [
      {TestRepo, [:passthrough],
       [get_by: fn _, _ -> %TestUser{id: 1, email: "test@email.com", encrypted_password: "not_encrypted"} end]}
    ] do
      %{valid?: valid?, changes: %{context: %{user: user}}} =
        Auth.ForgotPasswordForm.call(%{email: "test@email.com"}, %{repo: TestRepo, schema: TestUser})

      assert valid?
      refute is_nil(user)
    end
  end
end
