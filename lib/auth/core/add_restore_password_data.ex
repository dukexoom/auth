defmodule Auth.AddRestorePasswordData do
  @moduledoc false
  def call(user, repo) do
    restore_hash = Ext.Utils.Repo.generate_uniq_hash(user.__struct__, :restore_hash, 30, repo)

    repo.save!(user, %{restore_hash: restore_hash, restore_expire: Timex.shift(DateTime.utc_now(), hours: 1)})
  end
end
