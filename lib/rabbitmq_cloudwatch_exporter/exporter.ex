# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019-2020, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.Exporter do
  @moduledoc """
  Periodically collects and exports all selected metrics to AWS CloudWatch.
  """

  use GenServer

  alias :timer, as: Timer
  alias :rabbit_log, as: RabbitLog
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
  @default_resolution 60
  @default_namespace "RabbitMQ"
  @appname :rabbitmq_cloudwatch_exporter
  @collectors %{:overview => &OverviewMetrics.collect_overview_metrics/1,
                :vhost => &VHostMetrics.collect_vhost_metrics/1,
                :node => &NodeMetrics.collect_node_metrics/1,
                :exchange => &ExchangeMetrics.collect_exchange_metrics/1,
                :queue => &QueueMetrics.collect_queue_metrics/1,
                :connection => &ConnectionMetrics.collect_connection_metrics/1,
                :channel => &ChannelMetrics.collect_channel_metrics/1}

  def init(_) do
    try do
      options = application_options()

      Process.send_after(self(), :export_metrics, Timer.seconds(options[:period]))

      {:ok, options}
    rescue
      error in Regex.CompileError ->
        RabbitLog.error("Disabling rabbitmq_cloudwatch_exporter: ~p ~n", [error])
        {:ok, :error}
    end
  end

  def handle_info(:export_metrics, options) do
    options[:collectors]
      |> Enum.flat_map(fn({c, o}) -> @collectors[c].(o) end)
      |> Enum.filter(fn(m) -> m[:value] != nil end)
      |> Enum.map(fn(m) -> update_metric_datum(m, options) end)
      |> export_metrics(options[:namespace], options[:aws])

    Process.send_after(self(), :export_metrics, Timer.seconds(options[:period]))

    {:noreply, options}
  end

  def handle_info({:ssl_closed, _msg}, state), do: {:noreply, state}

  # Retrieve application options
  defp application_options() do
    metrics = Application.get_env(@appname, :metrics, [])
    collectors_options = @collectors
      |> Map.keys()
      |> Enum.flat_map(fn(c) -> metrics_options(metrics, c) end)
      |> Enum.map(&compile_regex_patterns/1)

    [aws: aws_options(),
     period: Application.get_env(@appname, :export_period, @default_export_period),
     resolution: Application.get_env(@appname, :storage_resolution, @default_resolution),
     namespace: Application.get_env(@appname, :namespace, @default_namespace)
       |> to_string()
       |> String.trim("\""),
     collectors: collectors_options]
  end

  # Retrieve and sanitize AWS specific options
  defp aws_options() do
    Application.get_env(@appname, :aws, [])
      |> Keyword.take([:region, :access_key_id, :secret_access_key])
      |> Enum.map(fn({option, value}) ->
                    {option, value |> to_string() |> String.trim("\"")}
                  end)
  end

  # Retrieve options for enabled metrics
  defp metrics_options(metrics, name) do
    if metrics |> Keyword.get(name, []) |> Keyword.get(:enable, false) do
      options = metrics
        |> Keyword.get(name)
        |> Keyword.take([:export_regex, :export_metrics])
        |> Enum.map(fn({k, o}) -> {k, sanitize_option(o)} end)

      [{name, options}]
    else
      []
    end
  end

  # Sanitize all values of the given option
  defp sanitize_option(options = [option | _]) when is_list(option) do
    Enum.map(options, &sanitize_option/1)
  end

  defp sanitize_option(option) when is_atom(option) do
    sanitize_option(option) |> String.to_atom()
  end

  defp sanitize_option(option) do
    option |> to_string() |> String.trim("\"")
  end

  # Compile regular expressions provided in configuration
  def compile_regex_patterns({metric, options}) do
    regex_metrics = [:exchange, :queue, :connection, :channel]

    if metric in regex_metrics and Keyword.has_key?(options, :export_regex) do
      {metric, Keyword.update!(options, :export_regex, &Regex.compile!/1)}
    else
      {metric, options}
    end
  end

  # Add cluster name and StorageResolution parameters to MetricDatum
  defp update_metric_datum(metric_datum, options) do
    cluster = RabbitNodes.cluster_name()

    metric_datum
      |> Keyword.update(:dimensions, [], &(([{"Cluster", cluster} | &1])))
      |> Keyword.put(:storage_resolution, options[:resolution])
  end

  # Export the collected metrics splitting the requests in chunks according to AWS CW limits
  defp export_metrics(metrics, namespace, options) do
    Enum.map(Enum.chunk_every(metrics, @request_chunk_size),
      fn(chunk) ->
        data = ExAws.Cloudwatch.put_metric_data(chunk, namespace)

        case ExAws.request(data, options) do
          {:ok, _} -> :ok
          {:error, error} ->
            RabbitLog.error(
              "Unable to publish metrics to CloudWatch: ~p~n"
              <> "Error: ~p", [chunk, error])
        end
      end)
  end
end
