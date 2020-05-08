defmodule Auth.Providers.Authorize do
  require IEx

  def call(
        %{provider: provider} = args,
        %{repo: repo, schemas: %{user: user_schema, auth: auth_schema}, required_fields: required_fields} = params
      ) do
    uid = Auth.Providers.GetUserUniqKey.call(args)

    user_assoc = Ext.Ecto.Schema.get_schema_assoc(auth_schema, user_schema)

    case auth_schema
         |> repo.get_by(%{provider: provider, uid: uid})
         |> repo.preload(user_assoc) do
      nil ->
        if Auth.CheckCloseSignUp.call(user_schema),
          do: {:error, :sign_up_closed},
          else: Auth.Providers.SignUp.call(args, uid, params)

      authorization ->
        authorization
        |> Ext.Utils.Base.get_in([user_assoc])
        |> Auth.Providers.SignIn.call(authorization, required_fields)
    end
  end
end
