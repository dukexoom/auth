defmodule Auth.ForgotPasswordForm do
  @moduledoc false
  use Ext.BaseForm

  Ext.BaseForm.schema "" do
    field(:email, :string, virtual: true, required: true)
  end

  def changeset(form) do
    form
    |> fetch_user()
    |> validate_user()
  end

  defp fetch_user(%{changes: %{email: email, context: %{repo: repo, schema: schema}}} = form),
    do: __MODULE__.with_context(form, %{user: repo.get_by(schema, email: email)})

  defp validate_user(%{changes: %{email: email, context: %{user: nil}}} = form),
    do: add_error(form, :email, "Email #{email} not found")

  defp validate_user(%{changes: %{context: %{user: _user}}} = form), do: form
end
