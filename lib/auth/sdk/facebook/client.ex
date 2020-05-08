defmodule Auth.SDK.Facebook.Client do
  use SDK.BaseClient, endpoints: Map.keys(Auth.SDK.Facebook.Config.data().endpoints)
  require IEx
  require Logger
end
