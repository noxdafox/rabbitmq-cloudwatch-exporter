defmodule RabbitMQ.CloudWatchExporter.Collector do

  use Task

  alias :timer, as: Timer
  alias :rabbit_nodes, as: RabbitNodes
  alias RabbitMQ.CloudWatchExporter.OverviewMetrics, as: OverviewMetrics
  alias RabbitMQ.CloudWatchExporter.VHostMetrics, as: VHostMetrics
  alias RabbitMQ.CloudWatchExporter.ExchangeMetrics, as: ExchangeMetrics
  alias RabbitMQ.CloudWatchExporter.QueueMetrics, as: QueueMetrics
  alias RabbitMQ.CloudWatchExporter.NodeMetrics, as: NodeMetrics
  alias RabbitMQ.CloudWatchExporter.ConnectionMetrics, as: ConnectionMetrics
  alias RabbitMQ.CloudWatchExporter.ChannelMetrics, as: ChannelMetrics

  @appname :rabbitmq_cloudwatch_exporter
  @collectors %{:overview => &OverviewMetrics.collect_overview_metrics/0,
                :vhost => &VHostMetrics.collect_vhost_metrics/0,
                :node => &NodeMetrics.collect_node_metrics/0,
                :exchange => &ExchangeMetrics.collect_exchange_metrics/0,
                :queue => &QueueMetrics.collect_queue_metrics/0,
                :connection => &ConnectionMetrics.collect_connection_metrics/0,
                :channel => &ChannelMetrics.collect_channel_metrics/0}

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    cluster = RabbitNodes.cluster_name()
    period = Application.get_env(@appname, :export_period, 60)
    enabled_collectors = Application.get_env(@appname, :metrics, [])

    receive do
    after
      Timer.seconds(period) ->
        metrics = enabled_collectors
          |> Enum.flat_map(fn c -> @collectors[c].() end)
          |> Enum.map(fn m ->
                        Keyword.update(m, :dimensions, [],
                                       fn c -> ([{"Cluster", cluster} | c]) end)
                      end)

        {:ok, device} = File.open("/tmp/test_rabbit.ex", [:write, :utf8])
        IO.inspect(device, metrics, [limit: :infinity])
        :ok = File.close(device)

        # ExAws.Cloudwatch.put_metric_data(metrics, "RabbitMQMetrics")

        run()
    end
  end
end
