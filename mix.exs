defmodule Samhstn.MixProject do
  use Mix.Project

  @version "1.0.0"
  @elixir_version "1.10"

  def project do
    [
      app: :samhstn,
      version: @version,
      elixir: "~> #{@elixir_version}",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      config_path: "config.exs",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Samhstn.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.5.4"},
      {:phoenix_html, "~> 2.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
