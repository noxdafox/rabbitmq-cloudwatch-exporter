defmodule RabbitMQ.MetricsCollectorPlugin.Application do
  use Application

  def start(_type, _args) do
    children = [RabbitMQ.MetricsCollectorPlugin.Collector]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
