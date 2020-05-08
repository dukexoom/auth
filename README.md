# Auth
Auth resolver for Graphql

## Content
* [Installation](#installation)
* [Setup server](#setup-server)
    - [Auth struct](#auth-struct)
    - [Mutations](#mutations)
    - [Setup Google oauth](#setup-google-oauth)
    - [Setup Facebook oauth](#setup-facebook-oauth)
    - [Setup Twitter oauth](#setup-twitter-oauth)
* [Setup client](#setup-client-for-internal-use)
* [Auth Plug](#auth-plug)


## Installation

1. Add `auth` to your list of dependencies in `mix.exs`.
    ```elixir
    def deps do
      [
        {:auth, git: "https://github.com/dukexoom/auth.git"}
      ]
    end
    ```

2. Update dependencies by running:
    ```sh
    $ mix deps.get
    ```
## Setup server
1. Fill in config for auth (how to configure oauth apps for providers see below):
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "",
      facebook_client_id: "",
      facebook_client_secret: "",
      twitter_consumer_key: "",
      twitter_consumer_secret: "",
      twitter_access_token: "",
      twitter_access_token_secret: "",
      close_sign_up: [User],
      joken_default_exp: 900
    ```
   `close_sign_up` - list of structs for which sign up is to be canceled
   `joken_default_exp` - expiration of JWT `access_token`

2. Create table for authorization records. Example:
    * migration:
        ```elixir
        defmodule Repo.Migrations.CreateAuthorizations do
          use Ecto.Migration

          def change do
            create table(:authorizations) do
              add(:user_id, references(:users, on_delete: :delete_all))
              add(:provider, :smallint)
              add(:uid, :string)
              timestamps(type: :timestamptz)
            end

            create(index(:authorizations, [:user_id]))
            create(unique_index(:authorizations, [:provider, :uid]))
          end
        end
        ```
    * schema:
        ```elixir
        defmodule Authorization do
          @moduledoc false
          use Schema

          import EctoEnum, only: [defenum: 2]
          defenum ProviderEnum, facebook: 0, google: 1, twitter: 2

          schema "authorizations" do
            field :provider, ProviderEnum
            field :uid, :string
            belongs_to :user, User
            timestamps()
          end

          def changeset(struct, params \\ %{}) do
            struct
            |> cast(params, [:provider, :uid, :user_id])
          end
        end
        ```
3. Create table for auth devices records. Example:
    * migration:
        ```elixir
        defmodule Fun.Repo.Migrations.CreateAuthDevices do
          use Ecto.Migration

          def change do
            create table(:auth_devices) do
              add(:user_id, references(:users, on_delete: :delete_all))
              add(:uuid, :string)
              add(:refresh_token, :string)
              add(:location, :string)
              add(:ip, :inet)
              add(:browser, :string)
              add(:platform, :string)
              timestamps(type: :timestamptz)
            end

            create(unique_index(:auth_devices, [:uuid]))
            create(unique_index(:auth_devices, [:refresh_token]))

            alter table(:users) do
              remove(:refresh_token, :string)
            end
          end
        end

        ```
    * schema:
        ```elixir
        defmodule AuthDevice do
          @moduledoc false
          use Fun.Schema

          schema "auth_devices" do
            field :uuid, :string
            field :refresh_token, :string
            field :location, :string
            field :ip, EctoNetwork.INET
            field :browser, :string
            field :platform, :string
            belongs_to :user, User
            timestamps()
          end

          def changeset(struct, params \\ %{}) do
            struct |> cast(params, [:uuid, :refresh_token, :location, :ip, :browser, :platform, :user_id])
          end
        end
        ```
    Note: For ip field type use ecto_network dependencie

3. Add `restore_hash` add `restore_expire` fields to `users` table.
   Add `authorizations` and `auth_devices` associations to User schema
    * migration
        ```elixir
          defmodule Repo.Migrations.AddRestoreDataToUsers do
            use Ecto.Migration

            def change do
              alter table(:users) do
                add(:restore_hash, :string)
                add(:restore_expire, :timestamptz)
              end

              create(unique_index(:users, :restore_hash))
            end
          end
        ```
    * schema:
        ```elixir
          defmodule User do
            @moduledoc false
            use Fun.Schema

            schema "users" do
              ...
              field :email, :string
              field :encrypted_password, :string, default: ""
              field :password, :string, virtual: true
              field :password_confirmation, :string, virtual: true

              field :restore_hash, :string
              field :restore_expire, :utc_datetime_usec

              has_many :authorizations, Authorization, on_replace: :delete
              has_many :auth_devices, AuthDevice, on_replace: :delete
              ...
            end

            def changeset(struct, params \\ %{}) do
              struct
              |> cast(params, [
                ...
                :restore_hash,
                :restore_expire,
                ...
              ])
            end
          end
        ```
4. Create initializer for oauth (path: `lib/bomb_brawl/initializers/oauth.ex`) and
   add `Ext.RunInitializers.call(<app_name>)` to `start` function of `application.ex`
    ```elixir
    defmodule Initializers.Oauth do
      @moduledoc false

      def call do
        ExTwitter.configure(
          consumer_key: Application.get_env(:bomb_brawl, :oauth)[:twitter_consumer_key],
          consumer_secret: Application.get_env(:bomb_brawl, :oauth)[:twitter_consumer_secret],
          access_token: Application.get_env(:bomb_brawl, :oauth)[:twitter_access_token],
          access_token_secret: Application.get_env(:bomb_brawl, :oauth)[:twitter_access_token_secret53]
        )
      end
    end
    ```
5. If it necessary create form for required fields. Example:
    ```elixir
    defmodule OAuth.SetEmailForm do
      @moduledoc false
      use Ext.BaseForm

      Ext.BaseForm.schema "" do
        field(:email, :string, required: true)
        field(:first_name, :string, required: true)
      end

      def changeset(params, context \\ %{}) do
        build_args(params, context)
        |> validate_required(context.missing_fields)
        |> Ext.Validators.Email.call(%{field: :email, message: "Invalid email format"})
        |> Ext.Validators.Uniq.call(%{schema: User, repo: Repo, fields: [:email], message: "Not unique"})
      end
    end
    ```
6. Create validation form for `sign_up`:
    ```elixir
     defmodule Users.SaveForm do
       @moduledoc false
       use Ext.BaseForm

       Ext.BaseForm.schema "" do
         field :id, :integer
         field :email, :string
         field :password, :string, virtual: true
         field :password_confirmation, :string, virtual: true
       end

       def changeset(form) do
         form
         |> validate_length(:password, min: 6)
         |> Auth.Validators.Password.call()
         |> Ext.Validators.Email.call(%{field: :email})
         |> Ext.Validators.Uniq.call(%{schema: User, repo: Fun.Repo, fields: [:email]})
       end
     end
    ```
7. Create caller for sending message to email for restore password:
    ```elixir
     defmodule Auth.SendEmail do
       def call(from_email) do
         fn (user, restore_url) ->
           user.email
           |> AppWeb.Emails.Auth.reset_password_email(from_email, user.restore_hash, restore_url)
           |> AppWeb.Mailer.deliver_later()
         end
       end
     end
    ```
### Auth struct
Add
```elixir
defmodule GQL.Auth.Struct do
  @moduledoc false
  use Absinthe.Schema.Notation

  object :auth do
    field :access_token, :string
    field :refresh_token, :string
    field :current_user, :user
    field :device_uuid, :string
  end

  object :user do
    field :id, :integer
    field :email, :string
  end
end
```

### Mutations
1. Sign In
    ```elixir
     object :auth_mutations do
       field :sign_in, type: :auth do
         arg :email, non_null(:string)
         arg :password, non_null(:string)

         resolve Auth.Resolver.sign_in(%{repo: Repo, schemas: %{user: User, device: AuthDevice}})
       end
     end
    ```

2. Sign Up
    ```elixir
     input_object :sign_up_params do
       field :email, non_null(:string)
       field :password, non_null(:string)
       field :password_confirmation, non_null(:string)
     end

     object :auth_mutations do
       field :sign_up, type: :auth do
         arg :entity, :sign_up_params

         resolve Auth.Resolver.sign_up(%{repo: Repo, schemas: %{user: User, device: AuthDevice}}, form: Users.SaveForm})
       end
     end
    ```

3. Forgot Password
    ```elixir
     object :auth_mutations do
       field :forgot_password, type: :string do
         arg :email, non_null(:string)
         arg :restore_url, non_null(:string)

         resolve Auth.Resolver.forgot_password(%{
           repo: Repo,
           schema: User,
           send_caller: Auth.SendEmail.call(System.get_env("DASHBOARD_EMAIL"))
         })
       end
     end
    ```

4. Restore Password
    ```elixir
     input_object :restore_params do
       field :restore_hash, non_null(:string)
       field :password, non_null(:string)
       field :password_confirmation, non_null(:string)
     end

     object :auth_mutations do
        field :restore_password, type: :auth do
          arg :entity, :restore_params
          arg :device_uuid, :string

          resolve Auth.Resolver.restore_password(%{
            repo: Repo,
            schemas: %{user: User, device: AuthDevice}},
            form:  Users.SaveForm
          })
        end
     end
    ```

5. Refresh Token
    ```elixir
     object :auth_mutations do
        field :refresh_token, type: :auth do
          arg :refresh_token, :string
          arg :device_uuid, :string

          resolve Auth.Resolver.refresh_token(%{
            repo: Repo,
            schemas: %{user: User, device: AuthDevice}},
          })
        end
     end
    ```

6. Start authentication by provider:
    ```elixir
    enum(:provider_types, values: [:facebook, :google, :twitter])

    field :provider_auth, type: :user do
          arg :payload, non_null(:snake_keys_json)
          arg :provider, non_null(:provider_types)
          arg :device_uuid, :string

          resolve Auth.Resolver.provider_auth(%{
                    repo: Repo,
                    schemas: %{user: User, auth: Authorization, device: AuthDevice},
                    required_fields: [:email, :first_name]
                  })
        end
    ```
    Payload example:
    * Google:
        ```json
        {"id_token": "fake_google_user_token"}
        ```
    * Facebook:
        ```json
        {
          "accessToken": "fake_facebook_user_token",
          "userID": "fake_user_id",
          "expiresIn": 1000,
          "signedRequest": "fake_signed_request",
          "data_access_expiration_time": 1577090601
        }
        ```
    * Twitter:
    ```json
    {"oauth_token": "fake_oauth_token", "oauth_verifier": "fake_oauth_verifier"}
    ```
7. Finish authentication and check required fields:
    ```elixir
    input_object :oauth_user_params do
      field :email, :string
      field :first_name, :string
    end

    input_object :oauth_data_params do
      field :uid, :string
      field :provider, :provider_types
    end

    field :complete_oauth, type: :user do
          arg :entity, non_null(:oauth_user_params)
          arg :oauth_data, non_null(:oauth_data_params)
          arg :device_uuid, :string

          resolve Auth.Resolver.complete(%{
                    repo: Repo,
                    schemas: %{user: User, auth: Authorization, device: AuthDevice},
                    required_fields: [:email, :first_name],
                    form: Form # Form for validate required fields
                  })
        end
    ```
8. Mutation for getting twitter authenticate url:
    ```elixir
    field :twitter_authenticate_url, type: :string do
          arg :callback_url, non_null(:string)

          resolve &Auth.Resolver.twitter_authenticate_url/2
        end
    ```
### Setup Google oauth
1. Create new google project (https://console.developers.google.com).
2. On tab `OAuth consent screen` fill in `Application name` and `Authorized domains` fields.
3. On tab `Credentials` create `OAuth client ID`. Choose `Web application` type. Fill in
   `Authorized JavaScript origins` field by urls of your client app.
4. In config/config.exs, add `google_client_id`:
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "Client Id",
      facebook_client_id: "",
      facebook_client_secret: "",
      twitter_consumer_key: "",
      twitter_consumer_secret: "",
      twitter_access_token: "",
      twitter_access_token_secret: ""
    ```

#### Setup Facebook oauth
1. Create new facebook application (https://developers.facebook.com)
2. On tab `Settings > Basic` fill in the following fields:
    * `App Domains` - urls of your client app
    * `Privacy Policy URL` - link to Privacy Policy of your Company
    * `Site URL` - main domain
3. In config/config.exs, add `facebook_client_id` and `facebook_client_secret`:
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "",
      facebook_client_id: "App ID",
      facebook_client_secret: "App Secret",
      twitter_consumer_key: "",
      twitter_consumer_secret: "",
      twitter_access_token: "",
      twitter_access_token_secret: ""
    ```

#### Setup Twitter oauth
1. Create new twitter application (https://developers.facebook.com)
2. Fill in the following fields:
    * `Website URL` - main domain
    * `Enable Sign in with Twitter` - should be checked
    * `Callback URLs` - after clicking to sign in button, twitter redirect user to this url with oauth data in params
    * `Terms of service URL` and `Privacy policy URL` - required if you'd like to enable advanced permission settings.
    * `Tell us how this app will be used` - example: "This application be used only for sign in in our corporative administration dashboard and get base information for create new user."
3. Setup app Permissions. `Access permission`: `Read-only`. `Request email address from users` should be checked
4. In config/config.exs, add `twitter_consumer_key`, `twitter_consumer_secret`, `twitter_access_token` and `twitter_access_token_secret`:
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "",
      facebook_client_id: "",
      facebook_client_secret: "",
      twitter_consumer_key: "API key",
      twitter_consumer_secret: "API secret key",
      twitter_access_token: "Access token",
      twitter_access_token_secret: "Access token secret"
    ```
## Setup client (for internal use)
See https://trulysocialgames.atlassian.net/wiki/spaces/BBN/pages/1420492906/Auth+and+OAuth

## Auth Plug
Check user authorization by JWT access token in `Authorization` header.
Add to router:
```elixir
plug Auth.Plugs.Authenticate,
  repos: %{User => Fun.Repo, Manager => Fun.Repo},
  exclude: [
    :sign_in,
    :sign_up,
    :forgot_password,
    :restore_password,
    :provider_auth,
    :twitter_authenticate_url,
    :complete_oauth,
    :subscribe,
    :refresh_token
  ]
plug Auth.Plugs.GetDeviceData  # for saving device information (browser, platform, ip)
```
`repos` - map where key is user's schema, value is repo for this schema.
`exclude` - list of excluded mutations.
