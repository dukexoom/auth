defmodule Auth.Providers.GetUserUniqKey do
  def call(%{provider: provider, payload: payload}) do
    module = String.to_atom("Elixir.Auth.Providers.#{Macro.camelize("#{provider}")}.GetUserUniqKey")
    module.call(payload)
  end
end
