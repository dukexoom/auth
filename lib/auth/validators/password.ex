defmodule Auth.Validators.Password do
  @moduledoc false
  import Ecto.Changeset

  def call(%{changes: %{password: password, password_confirmation: password_confirmation}} = form) do
    if password_confirmation == password,
      do: form,
      else: add_error(form, :password_confirmation, "Passwords does not match")
  end

  def call(%{changes: %{password: _password}} = form),
    do: add_error(form, :password_confirmation, "Passwords confirmation is not filled")

  def call(form), do: form
end
