defmodule Auth.CheckCloseSignUp do
  def call(schema), do: schema in (Application.get_env(:auth, :close_sign_up) || [])
end
