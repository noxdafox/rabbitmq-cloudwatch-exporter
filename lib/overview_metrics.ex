defmodule RabbitMQ.CloudWatchExporter.OverviewMetrics do

  require RabbitMQ.CloudWatchExporter.Common

  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQ.CloudWatchExporter.Common, as: Common

  def collect_overview_metrics() do
    RabbitMGMTDB.get_overview(Common.no_range) |> overview_metrics()
  end

  defp overview_metrics(overview) do
    dimensions = [{"Metric", "ClusterOverview"}]

    Common.stats(Keyword.get(overview, :queue_totals, []), Common.message_counts)
      ++ Common.stats(Keyword.get(overview, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
