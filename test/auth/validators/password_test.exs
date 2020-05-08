defmodule Auth.Validators.PasswordTest do
  use Auth.ConnCase

  setup_with_mocks([{Ecto.Changeset, [:passthrough], [add_error: fn _, _, _ -> :_ end]}]) do
    :ok
  end

  test "valid" do
    Auth.Validators.Password.call(%{changes: %{password: "123qwe", password_confirmation: "123qwe"}})

    refute called(Ecto.Changeset.add_error(:_, :_, :_))
  end

  test "passwords does not match" do
    Auth.Validators.Password.call(%{changes: %{password: "123qwe", password_confirmation: "invalid"}})

    assert_called(Ecto.Changeset.add_error(:_, :password_confirmation, "Passwords does not match"))
  end

  test "passwords confirmation is not filled" do
    Auth.Validators.Password.call(%{changes: %{password: "123qwe"}})

    assert_called(Ecto.Changeset.add_error(:_, :password_confirmation, "Passwords confirmation is not filled"))
  end

  test "password not exists in params" do
    Auth.Validators.Password.call(%{changes: %{}})

    refute called(Ecto.Changeset.add_error(:_, :_, :_))
  end
end
