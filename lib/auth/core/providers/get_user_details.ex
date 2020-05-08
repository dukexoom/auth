defmodule Auth.Providers.GetUserDetails do
  def call(provider, auth_data) do
    module = String.to_atom("Elixir.Auth.Providers.#{Macro.camelize("#{provider}")}.GetUserDetails")

    module.call(auth_data) |> Map.from_struct()
  end
end
