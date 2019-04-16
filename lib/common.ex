defmodule RabbitMQ.MetricsCollectorPlugin.Common do

  alias :rabbit_vhost, as: RabbitVHost

  @message_stats [:publish, :confirm, :get, :get_no_ack, :deliver,
                  :deliver_no_ack, :redeliver, :ack, :deliver_get,
                  :get_empty, :publish_in, :publish_out, :return_unroutable]
  @message_counts [:messages_ready, :messages_unacknowledged, :messages]

  defmacro message_stats, do: @message_stats
  defmacro message_counts, do: @message_counts
  defmacro no_range, do: quote do: {:no_range, :no_range, :no_range, :no_range}

  def stats(list, stats_type) do
    for {keyword, value} <- list,
        Enum.member?(stats_type, keyword) do
      [metric_name: keyword
        |> Atom.to_string()
        |> String.split("_")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(),
       unit: "Count",
       value: value]
    end
  end

  def list_vhosts() do
    RabbitVHost.info_all([:name]) |> Enum.map(fn([name: vhost]) -> vhost end)
  end
end
