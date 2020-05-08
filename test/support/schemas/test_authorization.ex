defmodule TestAuthorization do
  use Ecto.Schema

  import EctoEnum, only: [defenum: 2]
  defenum ProviderEnum, facebook: 0, google: 1

  schema "test_authorizations" do
    field(:provider, ProviderEnum)
    field(:uid, :string)
    belongs_to(:test_user, TestUser)
  end
end
