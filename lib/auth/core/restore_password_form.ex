defmodule Auth.RestorePasswordForm do
  @moduledoc false
  use Ext.BaseForm

  Ext.BaseForm.schema "" do
    field(:restore_hash, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
  end

  def changeset(form) do
    form
    |> fetch_user()
    |> validate_restore_hash()
  end

  defp fetch_user(%{changes: %{restore_hash: restore_hash, context: %{repo: repo, schemas: %{user: schema}}}} = form),
    do:
      __MODULE__.with_context(form, %{
        user: repo.get_by(schema, restore_hash: restore_hash)
      })

  defp validate_restore_hash(%{changes: %{context: %{user: nil}}} = form),
    do: add_error(form, :password, "Invalid restore hash")

  defp validate_restore_hash(%{changes: %{context: %{user: user}}} = form) do
    case Timex.compare(DateTime.utc_now(), user.restore_expire) do
      1 -> add_error(form, :password, "Invalid restore hash")
      _ -> form
    end
  end
end
