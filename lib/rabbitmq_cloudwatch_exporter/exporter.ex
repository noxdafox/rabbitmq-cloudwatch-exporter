# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.Exporter do
  @moduledoc """
  Periodically collects and exports all selected metrics to AWS CloudWatch.
  """

  use GenServer

  alias :timer, as: Timer
  alias :rabbit_nodes, as: RabbitNodes
  alias RabbitMQCloudWatchExporter.OverviewMetrics, as: OverviewMetrics
  alias RabbitMQCloudWatchExporter.VHostMetrics, as: VHostMetrics
  alias RabbitMQCloudWatchExporter.ExchangeMetrics, as: ExchangeMetrics
  alias RabbitMQCloudWatchExporter.QueueMetrics, as: QueueMetrics
  alias RabbitMQCloudWatchExporter.NodeMetrics, as: NodeMetrics
  alias RabbitMQCloudWatchExporter.ConnectionMetrics, as: ConnectionMetrics
  alias RabbitMQCloudWatchExporter.ChannelMetrics, as: ChannelMetrics

  @request_chunk_size 20
  @default_export_period 60
  @default_namespace "RabbitMQ"
  @appname :rabbitmq_cloudwatch_exporter
  @collectors %{:overview => &OverviewMetrics.collect_overview_metrics/0,
                :vhost => &VHostMetrics.collect_vhost_metrics/0,
                :node => &NodeMetrics.collect_node_metrics/0,
                :exchange => &ExchangeMetrics.collect_exchange_metrics/0,
                :queue => &QueueMetrics.collect_queue_metrics/0,
                :connection => &ConnectionMetrics.collect_connection_metrics/0,
                :channel => &ChannelMetrics.collect_channel_metrics/0}

  def init(_) do
    options = [period: Application.get_env(@appname, :export_period, @default_export_period),
               collectors: Application.get_env(@appname, :metrics, []),
               namespace: Application.get_env(@appname, :namespace, @default_namespace)
                 |> to_string()
                 |> String.trim("\"")]
    request_options = Application.get_env(@appname, :aws, [])
      |> Keyword.take([:region, :access_key_id, :secret_access_key])
      |> Enum.map(fn({option, value}) -> {option, value |> to_string() |> String.trim("\"")} end)

    Process.send_after(self(), :export_metrics, Timer.seconds(options[:period]))

    {:ok, [options, request_options]}
  end

  def handle_info(:export_metrics, [options, request_options]) do
    cluster = RabbitNodes.cluster_name()

    Enum.flat_map(options[:collectors], fn c -> @collectors[c].() end)
      |> Enum.map(fn m ->
                    Keyword.update(m, :dimensions, [], &(([{"Cluster", cluster} | &1])))
                  end)
      |> export_metrics(options[:namespace], request_options)

    Process.send_after(self(), :export_metrics, Timer.seconds(options[:period]))

    {:noreply, [options, request_options]}
  end

  # Export the collected metrics splitting the requests in chunks according to AWS CW limits
  defp export_metrics(metrics, namespace, options) do
    Enum.map(Enum.chunk_every(metrics, @request_chunk_size),
      fn(chunk) ->
        ExAws.Cloudwatch.put_metric_data(chunk, namespace) |> ExAws.request!(options)
      end)
  end
end
