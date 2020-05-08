defmodule Auth.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:mock, "0.3.3", only: :test},
      {:ext, git: "https://github.com/dukexoom/ext.git"},
      {:sdk, git: "https://github.com/dukexoom/sdk.git"},
      {:joken, "~> 2.1"},
      {:extwitter, "~> 0.8"},
      {:ecto_enum, "~> 1.0"},
      {:bcrypt_elixir, "~> 2.0.0"},
      {:phoenix, "~> 1.4.3", only: :test},
      {:browser, "~> 0.4.4"}
    ]
  end
end
