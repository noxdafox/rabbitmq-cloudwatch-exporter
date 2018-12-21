defmodule RabbitMQ.MetricsCollectorPlugin.Supervisor do
  use Supervisor

  Module.register_attribute __MODULE__,
    :rabbit_boot_step,
    accumulate: true, persist: true

  @rabbit_boot_step {__MODULE__,
                     [description: "metrics collector plugin hello world",
                      mfa: {__MODULE__, :start_link, []},
                      requires: :notify_cluster]}


  def start_link() do
    case Supervisor.start_link(__MODULE__, [], name: __MODULE__) do
      {:ok, _pid} -> :ok
      _ -> :error
    end
  end

  @impl true
  def init(_arg) do
    children = [
      RabbitMQ.MetricsCollectorPlugin.Collector
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
