defmodule RabbitMQ.CloudWatchExporter.ExchangeMetrics do

  require RabbitMQ.CloudWatchExporter.Common

  alias :rabbit_exchange, as: RabbitExchange
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias :rabbit_mgmt_format, as: RabbitMGMTFormat
  alias RabbitMQ.CloudWatchExporter.Common, as: Common

  def collect_exchange_metrics() do
    Common.list_vhosts()
      |> Enum.flat_map(&RabbitExchange.info_all/1)
      |> Enum.map(&RabbitMGMTFormat.exchange/1)
      |> RabbitMGMTDB.augment_exchanges(Common.no_range, :basic)
      |> Enum.flat_map(&exchange_metrics/1)
  end

  defp exchange_metrics(exchange) do
    dimensions = [{"Metric", "Exchange"},
                  {"Exchange", Keyword.get(exchange, :name)},
                  {"Type", exchange |> Keyword.get(:type) |> Atom.to_string()},
                  {"VHost", Keyword.get(exchange, :vhost)}]
    Common.stats(Keyword.get(exchange, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
