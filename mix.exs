defmodule RabbitMQCloudWatchExporter.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :rabbitmq_cloudwatch_exporter,
      version: "1.0.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      deps_path: System.get_env("DEPS_DIR", "deps"),
      aliases: aliases()
    ]
  end

  def application() do
    [
      # The Application needs to depend on `rabbit` in order to be detected as a plugin.
      extra_applications: [:rabbit, :mnesia, :singleton],
      mod: {RabbitMQCloudWatchExporter, []},
      registered: [RabbitMQCloudWatchExporter]
    ]
  end

  defp deps() do
    [
      {:ex_aws, "~> 2.5.8"},
      {:ex_aws_cloudwatch, "~> 2.0.4"},
      {:singleton, "~> 1.4.0"},
      # Optional dependencies of above packages
      {:jason, "~> 1.4.4"},
      {:hackney, "~> 1.23.0"},
      {:configparser_ex, "~> 4.0"},
      {:decimal, "~> 2.0"},
      {:req, "~> 0.5.10"},
      {:sweet_xml, "~> 0.7"},
      {:brotli, "~> 0.3.1"},
      {:castore, "~> 1.0"},
      {:ezstd, "~> 1.0"},
      {:nimble_csv, "~> 1.0"},
      {:plug, "~> 1.0"},
      # Build dependencies
      {:mix_task_archive_deps, github: "rabbitmq/mix_task_archive_deps", runtime: false}
    ]
  end

  defp aliases() do
    [
      make_app: [
        "deps.get",
        "deps.compile",
        "compile"
      ],
      make_archives: [
        "archive.build.deps --destination=#{dist_dir()}",
        "archive.build.elixir --destination=#{dist_dir()}",
        "archive.build.all --destination=#{dist_dir()}"
      ]
    ]
  end

  defp dist_dir() do
    System.get_env("DIST_DIR", "plugins")
  end
end
