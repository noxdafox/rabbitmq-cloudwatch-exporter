defmodule RabbitMQCloudWatchExporter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rabbitmq_cloudwatch_exporter,
      version: "1.0.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps_path: "deps",
      deps: deps("deps"),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:rabbit, :mnesia, :singleton],
      mod: {RabbitMQCloudWatchExporter, []}
    ]
  end

  defp deps(deps_dir) do
    [
      {:ex_aws, "~> 2.1"},
      {:ex_aws_cloudwatch, "~> 2.0.4"},
      {:singleton, "~> 1.2.0"},
      {:poison, "~> 3.0"},
      {:hackney, "~> 1.16.0"},
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
