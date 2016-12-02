defmodule Cassandrex.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :cassandrex,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [test_task: "espec", tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test, espec: :test],
     deps: deps(),

     # Hex
     description: description(),
     package: package(),

     # Docs
     name: "Ecto",
     docs: [source_ref: "v#{@version}", main: "Cassandrex",
            canonical: "http://hexdocs.pm/cassandrex",
            source_url: "https://github.com/vintikzzz/cassandrex"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cqerl]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:cqerl, github: "matehat/cqerl", tag: "v1.0.2", only: :test},
    {:espec, "~> 1.2.0", only: :test},
    {:excoveralls, "~> 0.5", only: :test},
    {:ex_doc, "~> 0.14", only: :dev},
    {:credo, "~> 0.5", only: [:dev, :test]}]
  end

  defp description do
    """
    Cassandra driver for Elixir
    """
  end

  defp package do
    [maintainers: ["Pavel Tatarskiy"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/vintikzzz/cassandrex"},
     files: ~w(mix.exs README.md lib)]
  end
end
