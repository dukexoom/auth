defmodule Auth.Resolver do
  use Ext.GQL.Resolvers.Base
  import Ext.Utils.Map

  def sign_in(%{repo: repo} = params) do
    fn args, %{context: context} ->
      form = %{changes: %{context: %{user: user}}} = Auth.SignInForm.call(args, params)

      if form.valid? do
        device = Auth.GetOrCreateUserDevice.call(params, user.id, args[:device_uuid], context[:device_data])
        {:ok, Auth.GenerateJWTData.call(user, repo, device)}
      else
        send_errors(form)
      end
    end
  end

  def sign_up(%{repo: repo, schemas: %{user: schema}} = params) do
    fn args, %{context: context} = info ->
      if Auth.CheckCloseSignUp.call(schema) do
        send_errors("sign_up_closed")
      else
        case Ext.GQL.Resolvers.Base.create(schema, repo, params[:form]).(args, info) do
          {:ok, user} ->
            device = Auth.GetOrCreateUserDevice.call(params, user.id, nil, context[:device_data])
            {:ok, Auth.GenerateJWTData.call(user, repo, device)}

          error ->
            error
        end
      end
    end
  end

  def forgot_password(%{repo: repo, send_caller: send_caller} = params) do
    fn %{restore_url: restore_url} = args, _ ->
      form = %{changes: %{context: %{user: user}}} = Auth.ForgotPasswordForm.call(args, params)

      if form.valid? do
        user = Auth.AddRestorePasswordData.call(user, repo)
        send_caller.(user, restore_url)
        {:ok, "ok"}
      else
        send_errors(form)
      end
    end
  end

  def restore_password(%{repo: repo} = params) do
    fn %{entity: entity} = args, %{context: context} ->
      restore_form = %{changes: %{context: %{user: user}}} = Auth.RestorePasswordForm.call(entity, params)

      password_form =
        case params[:form] do
          nil -> %{valid?: true, errors: []}
          form -> form.call(entity)
        end

      if restore_form.valid? && password_form.valid? do
        device = Auth.GetOrCreateUserDevice.call(params, user.id, args[:device_uuid], context[:device_data])

        {:ok,
         user
         |> repo.save!(entity ||| %{restore_hash: nil, restore_expire: nil})
         |> Auth.GenerateJWTData.call(repo, device)}
      else
        send_errors(%{restore_form | errors: restore_form.errors ++ password_form.errors})
      end
    end
  end

  def refresh_token(%{repo: repo, schemas: %{user: user_schema, device: device_schema}} = params) do
    fn %{refresh_token: refresh_token} = args, _ ->
      user_assoc = Ext.Ecto.Schema.get_schema_assoc(device_schema, user_schema)

      case get_device(params, refresh_token, args[:device_uuid]) |> repo.preload(user_assoc) do
        nil -> send_errors("invalid_refresh_token", 401)
        device -> {:ok, device |> Ext.Utils.Base.get_in([user_assoc]) |> Auth.GenerateJWTData.call(repo, device)}
      end
    end
  end

  def provider_auth(%{repo: repo} = params) do
    fn args, %{context: context} ->
      case Auth.Providers.Authorize.call(args, params) do
        {:ok, user} ->
          device = Auth.GetOrCreateUserDevice.call(params, user.id, args[:device_uuid], context[:device_data])
          {:ok, Auth.GenerateJWTData.call(user, repo, device)}

        {:error, data} ->
          send_errors(data)
      end
    end
  end

  def twitter_authenticate_url(%{callback_url: callback_url}, _info) do
    token = ExTwitter.request_token(callback_url)
    ExTwitter.authenticate_url(token.oauth_token)
  end

  def complete(
        %{
          repo: repo,
          schemas: %{user: user_schema, auth: auth_schema},
          required_fields: required_fields,
          form: form
        } = params
      ) do
    fn %{entity: entity, oauth_data: oauth_data} = args, %{context: context} ->
      user_assoc = Ext.Ecto.Schema.get_schema_assoc(auth_schema, user_schema)

      case auth_schema |> repo.get_by(oauth_data) |> repo.preload(user_assoc) do
        nil ->
          raise("Invalid oauth_data")

        authorization ->
          user = Ext.Utils.Base.get_in(authorization, [user_assoc])

          missing_fields =
            required_fields -- (user |> Map.from_struct() |> Enum.filter(fn {_, v} -> v != nil end) |> Keyword.keys())

          form = form.call(entity, %{missing_fields: missing_fields})

          cond do
            form.valid? ->
              device = Auth.GetOrCreateUserDevice.call(params, user.id, args[:device_uuid], context[:device_data])
              {:ok, user |> repo.save!(entity) |> Auth.GenerateJWTData.call(repo, device)}

            true ->
              send_errors(form)
          end
      end
    end
  end

  defp get_device(_, _, nil), do: nil

  defp get_device(%{repo: repo, schemas: %{device: device_schema}}, refresh_token, device_uuid) do
    device_schema |> repo.get_by(%{refresh_token: refresh_token, uuid: device_uuid})
  rescue
    Ecto.Query.CastError -> nil
  end
end
