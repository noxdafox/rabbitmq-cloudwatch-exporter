defmodule RabbitMQCloudWatchExporter.Mixfile do
  use Mix.Project

  @appname :rabbitmq_cloudwatch_exporter

  def project do
    [
      app: @appname,
      version: "1.0.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps("deps"),
      deps_path: System.get_env("DEPS_DIR", "deps"),
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
      {:ex_aws, "~> 2.5.8"},
      {:ex_aws_cloudwatch, "~> 2.0.4"},
      {:singleton, "~> 1.4.0"},
      {:jason, "~> 1.4.4"},
      {:hackney, "~> 1.23.0"},
      {:mix_task_archive_deps, github: "noxdafox/mix_task_archive_deps"}
    ]
  end

  defp archive_dir do
    "#{System.get_env("ARCHIVE_DIR", "plugins")}/#{@appname}"
  end

  defp aliases do
    [
      make_deps: [
        "deps.get",
        "deps.compile"
      ],
      make_app: [
        "deps.get",
        "deps.compile",
        "compile"
      ],
      make_archives: [
        "archive.build.deps --destination=#{archive_dir()}",
        "archive.build.elixir --destination=#{archive_dir()}",
        "archive.build.all --destination=#{archive_dir()}"
      ]
    ]
  end
end
