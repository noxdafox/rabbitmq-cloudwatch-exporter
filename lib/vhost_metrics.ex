defmodule RabbitMQ.CloudWatchExporter.VHostMetrics do

  require RabbitMQ.CloudWatchExporter.Common

  alias :rabbit_vhost, as: RabbitVHost
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQ.CloudWatchExporter.Common, as: Common

  def collect_vhost_metrics() do
    RabbitVHost.info_all()
      |> RabbitMGMTDB.augment_vhosts(Common.no_range)
      |> Enum.flat_map(&vhost_metrics/1)
  end

  defp vhost_metrics(vhost) do
    dimensions = [{"Metric", "VHost"},
                  {"VHost", Keyword.get(vhost, :name)}]

    Common.stats(vhost, Common.message_counts)
      ++ Common.stats(Keyword.get(vhost, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
