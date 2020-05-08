defmodule Auth.SDK.Google.Client do
  use SDK.BaseClient, endpoints: Map.keys(Auth.SDK.Google.Config.data().endpoints)
  require IEx
  require Logger
end
