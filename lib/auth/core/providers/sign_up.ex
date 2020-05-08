defmodule Auth.Providers.SignUp do
  import Ext.Utils.Map

  def call(
        %{payload: payload, provider: provider} = args,
        uid,
        %{repo: repo, schemas: %{user: user_schema}, required_fields: required_fields} = params
      ) do
    user_details = Auth.Providers.GetUserDetails.call(provider, payload)

    user_details = if extra_params = args[:extra_params], do: user_details ||| extra_params, else: user_details

    user =
      if user_details.email,
        do: repo.get_or_insert!(user_schema, %{email: user_details.email}, user_details),
        else: repo.save!(user_schema.__struct__, user_details)

    authorization = create_authorizations(user, provider, uid, user_details.avatar, params)

    Auth.Providers.SignIn.call(user, authorization, required_fields)
  end

  defp create_authorizations(user, provider, uid, avatar, %{
         repo: repo,
         schemas: %{user: user_schema, auth: auth_schema}
       }) do
    user
    |> Ecto.build_assoc(Ext.Ecto.Schema.get_schema_assoc(user_schema, auth_schema), %{
      provider: provider,
      uid: uid
    })
    |> repo.save!(%{avatar: avatar})
  end
end
