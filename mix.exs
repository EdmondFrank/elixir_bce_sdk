defmodule ElixirBceSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_bce_sdk,
      version: "0.2.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mime, "~> 1.6"},
      {:confex, "~> 3.5"},
      {:poison, "~> 4.0"},
      {:httpoison, "~> 1.8"},
      {:espec, "~> 1.8.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
    ]
  end

  defp package do
    [
      maintainers: ["Edmond Frank"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/EdmondFrank/elixir_bce_sdk"},
      files: ~w(mix.exs README.md lib config)
    ]
  end

  defp description() do
    """
    Baidu Could Storage SDK for Elixir
    """
  end
end
