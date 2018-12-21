defmodule RabbitMQ.MetricsCollectorPlugin.Collector do
  use Task

  import Record, only: [defrecord: 2, extract: 2]

  alias :ets, as: ETS
  alias :timer, as: Timer
  alias :rabbit_nodes, as: RabbitNodes
  alias :rabbit_vhost, as: RabbitVHost
  alias :rabbit_mnesia, as: RabbitMnesia
  alias :rabbit_amqqueue, as: RabbitQueue
  alias :rabbit_exchange, as: RabbitExchange
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias :rabbit_mgmt_format, as: RabbitMGMTFormat

  defrecord :slide, extract(
    :slide, from: "deps/rabbitmq_management_agent/src/exometer_slide.erl")

  @no_range {:no_range, :no_range, :no_range, :no_range}
  @message_stats [:publish, :confirm, :get, :get_no_ack, :deliver,
                  :deliver_no_ack, :redeliver, :ack, :deliver_get,
                  :get_empty, :publish_in, :publish_out, :return_unroutable]
  @message_counts [:messages_ready, :messages_unacknowledged, :messages]

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    receive do
    after
      Timer.seconds(10) ->
        cluster = RabbitNodes.cluster_name()
        metrics =
          collect_overview_metrics()
          ++ collect_vhost_metrics()
          ++ collect_exchange_metrics()
          ++ collect_queue_metrics()
          ++ collect_node_metrics()
          ++ collect_connection_metrics()
          ++ collect_channel_metrics()
          |> Enum.map(fn(m) ->
            Keyword.update(m, :dimensions, [], &([{"Cluster", cluster} | &1]))
          end)

        {:ok, device} = File.open("/tmp/test_rabbit.ex", [:write, :utf8])
        IO.inspect(device, metrics, [limit: :infinity])
        :ok = File.close(device)

        run()
    end
  end

  defp collect_overview_metrics() do
    RabbitMGMTDB.get_overview(@no_range) |> overview_metrics()
  end

  defp collect_vhost_metrics() do
    RabbitVHost.info_all()
      |> RabbitMGMTDB.augment_vhosts(@no_range)
      |> Enum.flat_map(&vhost_metrics/1)
  end

  defp collect_exchange_metrics() do
    list_vhosts()
      |> Enum.flat_map(&RabbitExchange.info_all/1)
      |> Enum.map(&RabbitMGMTFormat.exchange/1)
      |> RabbitMGMTDB.augment_exchanges(@no_range, :basic)
      |> Enum.flat_map(&exchange_metrics/1)
  end

  defp collect_queue_metrics() do
    list_vhosts()
      |> Enum.flat_map(&RabbitQueue.list/1)
      |> Enum.map(&RabbitMGMTFormat.queue/1)
      |> RabbitMGMTDB.augment_queues(@no_range, :basic)
      |> Enum.flat_map(&queue_metrics/1)
  end

  defp collect_node_metrics() do
    list_nodes()
      |> RabbitMGMTDB.augment_nodes(@no_range)
      |> Enum.flat_map(&node_metrics/1)
  end

  defp collect_connection_metrics() do
    RabbitMGMTDB.get_all_connections(@no_range)
      |> Enum.flat_map(&connection_metrics/1)
  end

  defp collect_channel_metrics() do
    RabbitMGMTDB.get_all_channels(@no_range)
      |> Enum.flat_map(&channel_metrics/1)
  end

  defp overview_metrics(overview) do
    dimensions = [{"Metric", "ClusterOverview"}]
    stats(Keyword.get(overview, :queue_totals, []), @message_counts)
      ++ stats(Keyword.get(overview, :message_stats, []), @message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end

  defp vhost_metrics(vhost) do
    dimensions = [{"Metric", "VHost"},
                  {"VHost", Keyword.get(vhost, :name)}]
    stats(vhost, @message_counts)
      ++ stats(Keyword.get(vhost, :message_stats, []), @message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end

  defp exchange_metrics(exchange) do
    dimensions = [{"Metric", "Exchange"},
                  {"Exchange", Keyword.get(exchange, :name)},
                  {"Type", exchange |> Keyword.get(:type) |> Atom.to_string()},
                  {"VHost", Keyword.get(exchange, :vhost)}]
    stats(Keyword.get(exchange, :message_stats, []), @message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end

  defp queue_metrics(queue) do
    metrics =
      [
        [metric_name: "Memory",
         unit: "Bytes",
         value: Keyword.get(queue, :memory, 0)],
        [metric_name: "Consumers",
         unit: "Count",
         value: Keyword.get(queue, :consumers, 0)]
      ]
    dimensions = [{"Metric", "Queue"},
                  {"Queue", Keyword.get(queue, :name)},
                  {"VHost", Keyword.get(queue, :vhost)}]

    metrics
      ++ queue_priorities(queue)
      ++ stats(queue, @message_counts)
      ++ stats(Keyword.get(queue, :message_stats, []), @message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end

  defp node_dimensions(node) do
    [{"Metric", "Node"},
     {"Node", node |> Keyword.get(:name) |> Atom.to_string()},
     {"Type", node |> Keyword.get(:type) |> Atom.to_string()}]
  end

  defp node_dimensions(node, limit) do
    [{"Limit", Keyword.get(node, limit)} | node_dimensions(node)]
  end

  defp node_metrics(node) do
    [
      [metric_name: "Uptime",
       unit: "Milliseconds",
       value: Keyword.get(node, :uptime),
       dimensions: node_dimensions(node)],
      [metric_name: "Memory",
       unit: "Bytes",
       value: Keyword.get(node, :mem_used),
       dimensions: node_dimensions(node, :mem_limit)],
      [metric_name: "DiskFree",
       unit: "Bytes",
       value: Keyword.get(node, :disk_free),
       dimensions: node_dimensions(node, :disk_free_limit)],
      [metric_name: "FileDescriptors",
       unit: "Count",
       value: Keyword.get(node, :fd_used),
       dimensions: node_dimensions(node, :fd_total)],
      [metric_name: "Sockets",
       unit: "Count",
       value: Keyword.get(node, :sockets_used),
       dimensions: node_dimensions(node, :sockets_total)],
      [metric_name: "Processes",
       unit: "Count",
       value: Keyword.get(node, :proc_used),
       dimensions: node_dimensions(node, :proc_total)],
      [metric_name: "IORead",
       unit: "Count",
       value: Keyword.get(node, :io_read_count),
       dimensions: node_dimensions(node)],
      [metric_name: "IORead",
       unit: "Bytes",
       value: Keyword.get(node, :io_read_bytes),
       dimensions: node_dimensions(node)],
      [metric_name: "IOWrite",
       unit: "Count",
       value: Keyword.get(node, :io_write_count),
       dimensions: node_dimensions(node)],
      [metric_name: "IOWrite",
       unit: "Bytes",
       value: Keyword.get(node, :io_write_bytes),
       dimensions: node_dimensions(node)],
      [metric_name: "IOSync",
       unit: "Count",
       value: Keyword.get(node, :io_sync_count),
       dimensions: node_dimensions(node)],
      [metric_name: "IOSeek",
       unit: "Count",
       value: Keyword.get(node, :io_seek_count),
       dimensions: node_dimensions(node)],
      [metric_name: "MnesiaRamTransactions",
       unit: "Count",
       value: Keyword.get(node, :mnesia_ram_tx_count),
       dimensions: node_dimensions(node)],
      [metric_name: "MnesiaDiskTransactions",
       unit: "Count",
       value: Keyword.get(node, :mnesia_disk_tx_count),
       dimensions: node_dimensions(node)],
    ]
  end

  defp connection_metrics(connection) do
    metrics =
      [
        [metric_name: "Channels",
         unit: "Count",
         value: Keyword.get(connection, :channels, 0)],
        [metric_name: "Sent",
         unit: "Count",
         value: Keyword.get(connection, :send_cnt, 0)],
        [metric_name: "Received",
         unit: "Count",
         value: Keyword.get(connection, :recv_cnt, 0)],
        [metric_name: "Sent",
         unit: "Bytes",
         value: Keyword.get(connection, :send_oct, 0)],
        [metric_name: "Received",
         unit: "Bytes",
         value: Keyword.get(connection, :recv_oct, 0)],
      ]
    dimensions = [{"Metric", "Connection"},
                  {"Node", Keyword.get(connection, :node)},
                  {"Connection", Keyword.get(connection, :name)},
                  {"Protocol", Keyword.get(connection, :protocol)},
                  {"AuthMechanism", Keyword.get(connection, :auth_mechanism)},
                  {"User", Keyword.get(connection, :user)},
                  {"VHost", Keyword.get(connection, :vhost)}]

    metrics
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
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
      ++ stats(Keyword.get(channel, :message_stats, []), @message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end

  defp stats(list, stats_type) do
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

  defp queue_priorities(queue) do
    queue
      |> Keyword.get(:backing_queue_status, %{})
      |> Map.get(:priority_lengths, [])
      |> Enum.map(fn({level, size}) ->
                    [metric_name: "PriorityLevel#{level}",
                     unit: "Count",
                     value: size]
                  end)
  end

  defp list_vhosts() do
    RabbitVHost.info_all([:name]) |> Enum.map(fn([name: vhost]) -> vhost end)
  end

  defp list_nodes() do
    nodes = RabbitMnesia.status() |> Keyword.get(:nodes, [])
    running_nodes = Keyword.get(nodes, :running_nodes, [])

    for type <- Keyword.keys(nodes),
        node <- Keyword.get(nodes, type, []) do
      [name: node, type: type, running: Enum.member?(running_nodes, node)]
    end
  end
end
