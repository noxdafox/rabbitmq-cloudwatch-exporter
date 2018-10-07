defmodule RabbitMQ.MetricsCollectorPlugin.Supervisor do
  Module.register_attribute __MODULE__,
    :rabbit_boot_step,
    accumulate: true, persist: true

  @rabbit_boot_step {__MODULE__,
                     [description: "metrics collector plugin hello world",
                      mfa: {__MODULE__, :hello_world, []},
                      requires: :notify_cluster]}

  def hello_world() do
    IO.puts("Hello World!")
  end
end
