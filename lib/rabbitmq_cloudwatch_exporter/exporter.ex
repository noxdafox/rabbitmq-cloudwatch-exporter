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

  use Task, restart: :transient

  alias :timer, as: Timer
  alias :rabbit_nodes, as: RabbitNodes
  alias RabbitMQ.CloudWatchExporter.OverviewMetrics, as: OverviewMetrics
  alias RabbitMQ.CloudWatchExporter.VHostMetrics, as: VHostMetrics
  alias RabbitMQ.CloudWatchExporter.ExchangeMetrics, as: ExchangeMetrics
  alias RabbitMQ.CloudWatchExporter.QueueMetrics, as: QueueMetrics
  alias RabbitMQ.CloudWatchExporter.NodeMetrics, as: NodeMetrics
  alias RabbitMQ.CloudWatchExporter.ConnectionMetrics, as: ConnectionMetrics
  alias RabbitMQ.CloudWatchExporter.ChannelMetrics, as: ChannelMetrics

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

  def start_link(_) do
    options = [period: Application.get_env(@appname, :export_period, @default_export_period),
               collectors: Application.get_env(@appname, :metrics, []),
               namespace: Application.get_env(@appname, :namespace, @default_namespace)
                 |> to_string()
                 |> String.trim("\"")]
    request_options = Application.get_env(@appname, :aws, [])
      |> Keyword.take([:region, :access_key_id, :secret_access_key])
      |> Enum.map(fn({option, value}) -> {option, value |> to_string() |> String.trim("\"")} end)

    Task.start_link(__MODULE__, :run, [options, request_options])
  end

  def run(options, request_options) do
    cluster = RabbitNodes.cluster_name()

    receive do
    after
      Timer.seconds(options[:period]) ->
        Enum.flat_map(options[:collectors], fn c -> @collectors[c].() end)
          |> Enum.map(fn m ->
                        Keyword.update(m, :dimensions, [], &(([{"Cluster", cluster} | &1])))
                      end)
          |> export_metrics(options[:namespace], request_options)

        run(options, request_options)
    end
  end

  # Export the collected metrics splitting the requests in chunks according to AWS CW limits
  defp export_metrics(metrics, namespace, options) do
    Enum.map(Enum.chunk_every(metrics, @request_chunk_size),
      fn(chunk) ->
        ExAws.Cloudwatch.put_metric_data(chunk, namespace) |> ExAws.request!(options)
      end)
  end
end
