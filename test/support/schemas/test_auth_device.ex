defmodule TestAuthDevice do
  use Ecto.Schema

  @primary_key {:uuid, :binary_id, autogenerate: true}

  schema "test_auth_devices" do
    field :refresh_token, :string
    field :browser, :string
    field :platform, :string
    belongs_to(:test_user, TestUser)
  end
end
