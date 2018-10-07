defmodule RabbitMQ.MetricsCollectorPlugin.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rabbitmq_metrics_collector,
      version: "0.0.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps_path: "deps",
      deps: deps("deps"),
      aliases: aliases()
    ]
  end

  def application do
    [
      applications: [:rabbit, :mnesia],
    ]
  end

  defp deps(deps_dir) do
    [
      {
        :rabbit,
        path: Path.join(deps_dir, "rabbit"),
        compile: "true",
        override: true
      },
      {
        :rabbit_common,
        path: Path.join(deps_dir, "rabbit_common"),
        compile: "true",
        override: true
      }
    ]
  end

  defp aliases do
    [
      make_deps: [
        "deps.get",
        "deps.compile"
      ],
      make_app: [
        "compile"
      ],
      make_all: [
        "deps.get",
        "deps.compile",
        "compile"
      ]
    ]
  end
end
