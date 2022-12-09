defmodule Wiegand.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/smartrent/wiegand"

  def project() do
    [
      app: :wiegand,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application() do
    []
  end

  defp deps() do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :docs, runtime: false}
    ]
  end

  defp description() do
    "An encoder and decoder for various Wiegand card formats"
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:unmatched_returns, :error_handling, :missing_return, :extra_return]
    ]
  end

  defp docs() do
    [
      extras: ["CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
