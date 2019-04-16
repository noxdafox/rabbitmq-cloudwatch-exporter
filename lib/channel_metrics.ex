defmodule RabbitMQ.MetricsCollectorPlugin.ChannelMetrics do

  require RabbitMQ.MetricsCollectorPlugin.Common

  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQ.MetricsCollectorPlugin.Common, as: Common

  def collect_channel_metrics() do
    RabbitMGMTDB.get_all_channels(Common.no_range)
      |> Enum.flat_map(&channel_metrics/1)
  end

  defp channel_metrics(channel) do
    metrics =
      [
        [metric_name: "MessagesUnacknowledged",
         unit: "Count",
         value: Keyword.get(channel, :messages_unacknowledged, 0)],
        [metric_name: "MessagesUnconfirmed",
         unit: "Count",
         value: Keyword.get(channel, :messages_unconfirmed, 0)],
        [metric_name: "MessagesUncommitted",
         unit: "Count",
         value: Keyword.get(channel, :messages_uncommitted, 0)],
        [metric_name: "AknogwledgesUncommitted",
         unit: "Count",
         value: Keyword.get(channel, :acks_uncommitted, 0)],
        [metric_name: "PrefetchCount",
         unit: "Count",
         value: Keyword.get(channel, :prefetch_count, 0)],
        [metric_name: "GlobalPrefetchCount",
         unit: "Count",
         value: Keyword.get(channel, :global_prefetch_count, 0)]
      ]
    dimensions = [{"Metric", "Channel"},
                  {"Connection", channel
                    |> Keyword.get(:connection_details, [])
                    |> Keyword.get(:name, "")},
                  {"Channel", Keyword.get(channel, :name)},
                  {"User", Keyword.get(channel, :user)},
                  {"VHost", Keyword.get(channel, :vhost)}]

    metrics
      ++ Common.stats(Keyword.get(channel, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
