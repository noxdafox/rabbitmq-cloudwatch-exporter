# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.NodeMetrics do
  @moduledoc """
  Collects Node related metrics.
  """

  require RabbitMQCloudWatchExporter.Common

  alias :rabbit_mnesia, as: RabbitMnesia
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQCloudWatchExporter.Common, as: Common

  @type regex :: {Atom.t, Regex.t}

  @doc """
  Collect Node metrics in AWS CW format.
  """
  @spec collect_node_metrics([regex]) :: List.t
  def collect_node_metrics(_regex_patterns) do
    list_nodes()
      |> RabbitMGMTDB.augment_nodes(Common.no_range)
      |> Enum.flat_map(&node_metrics/1)
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
      [metric_name: "BytesIORead",
       unit: "Bytes",
       value: Keyword.get(node, :io_read_bytes),
       dimensions: node_dimensions(node)],
      [metric_name: "IOWrite",
       unit: "Count",
       value: Keyword.get(node, :io_write_count),
       dimensions: node_dimensions(node)],
      [metric_name: "BytesIOWrite",
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

  defp list_nodes() do
    nodes = RabbitMnesia.status() |> Keyword.get(:nodes, [])
    running_nodes = Keyword.get(nodes, :running_nodes, [])

    for type <- Keyword.keys(nodes),
        node <- Keyword.get(nodes, type, []) do
      [name: node, type: type, running: Enum.member?(running_nodes, node)]
    end
  end

  defp node_dimensions(node) do
    [{"Metric", "Node"},
     {"Node", node |> Keyword.get(:name) |> Atom.to_string()},
     {"Type", node |> Keyword.get(:type) |> Atom.to_string()}]
  end

  defp node_dimensions(node, limit) do
    [{"Limit", Keyword.get(node, limit)} | node_dimensions(node)]
  end
end
