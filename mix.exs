defmodule FlameDigitalOcean.MixProject do
  use Mix.Project

  def project do
    [
      app: :flame_digital_ocean,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flame, "~> 0.5.2"},
      {:httpoison, "~> 2.0"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
