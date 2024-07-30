defmodule NatsTestIex.MixProject do
  use Mix.Project

  def project do
    [
      app: :nats_test_iex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {NatsTestIex, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnat, "~> 1.8"},
      {:jetstream, "~> 0.0"},
      {:uuid, "~> 1.1"}
    ]
  end
end
