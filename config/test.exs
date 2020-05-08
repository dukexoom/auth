use Mix.Config

config :auth,
  google_client_id: "google_app_id",
  facebook_client_id: "facebook_app_id",
  joken_default_exp: 900

config :joken,
  hs256: [signer_alg: "HS256", key_octet: "jwt_secret"]
