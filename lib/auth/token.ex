defmodule Auth.Token do
  @moduledoc """
    ## Examples

      iex> Tokens.Auth.generate_and_sign!(%{"some" => "extra claim"}) # generate JWT token

      iex> Tokens.Auth.verify_and_validate(token) # verify and
  """
  use Joken.Config, default_signer: :hs256

  def token_config,
    do:
      default_claims(
        default_exp: Application.get_env(:auth, :joken_default_exp),
        skip: [:jti, :aud, :nbf, :iss, :iat]
      )
end
