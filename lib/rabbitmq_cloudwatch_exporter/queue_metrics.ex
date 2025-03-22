# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019-2025, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.QueueMetrics do
  @moduledoc """
  Collects Queue related metrics.
  """

  require RabbitMQCloudWatchExporter.Common

  alias :rabbit_amqqueue, as: RabbitQueue
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias :rabbit_mgmt_format, as: RabbitMGMTFormat
  alias RabbitMQCloudWatchExporter.Common, as: Common

  @type regex :: {:queue, Regex.t}

  @doc """
  Collect Queue metrics in AWS CW format.
  """
  @spec collect_queue_metrics(Keyword.t) :: List.t
  def collect_queue_metrics(options) do
    regex = Keyword.get(options, :export_regex, ~r/.*/)
    filter = Keyword.get(options, :export_metrics, [])

    Common.list_vhosts()
      |> Enum.flat_map(&RabbitQueue.list/1)
      |> Enum.map(&RabbitMGMTFormat.queue/1)
      |> RabbitMGMTDB.augment_queues(Common.no_range, :basic)
      |> Enum.filter(fn(q) -> String.match?(Keyword.get(q, :name, ""), regex) end)
      |> Enum.flat_map(&queue_metrics/1)
      |> Common.filter_metrics(filter)
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
      ++ Common.stats(queue, Common.message_counts)
      ++ Common.stats(Keyword.get(queue, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end

  defp queue_priorities(queue) do
    queue
      |> Keyword.get(:backing_queue_status, %{})
      |> Map.get(:priority_lengths, [])
      |> Enum.map(fn({level, size}) ->
                    [metric_name: "LengthPriorityLevel#{level}",
                     unit: "Count",
                     value: size]
                  end)
  end
end
