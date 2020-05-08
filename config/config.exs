use Mix.Config

case Mix.env() do
  :test -> import_config "test.exs"
  :dev -> import_config "dev.exs"
end
