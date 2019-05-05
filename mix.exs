defmodule RabbitMQ.CloudWatchExporter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rabbitmq_cloudwatch_exporter,
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
      extra_applications: [:rabbit, :mnesia],
      mod: {RabbitMQ.CloudWatchExporter.Application, []}
    ]
  end

  defp deps(deps_dir) do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_cloudwatch, "~> 2.0.4"},
      {:poison, "~> 3.0"},
      {:hackney, "~> 1.9"},
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
      },
      {
        :rabbitmq_management,
        path: Path.join(deps_dir, "rabbitmq_management"),
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
