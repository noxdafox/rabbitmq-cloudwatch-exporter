defmodule RabbitMQ.CloudWatchExporter.Application do
  use Application

  def start(_type, _args) do
    children = [RabbitMQ.CloudWatchExporter.Collector]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
