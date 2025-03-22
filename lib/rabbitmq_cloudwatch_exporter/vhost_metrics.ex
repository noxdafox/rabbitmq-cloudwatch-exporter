# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019-2025, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.VHostMetrics do
  @moduledoc """
  Collects VHost related metrics.
  """

  require RabbitMQCloudWatchExporter.Common

  alias :rabbit_vhost, as: RabbitVHost
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQCloudWatchExporter.Common, as: Common

  @type regex :: {Atom.t, Regex.t}

  @doc """
  Collect VHost metrics in AWS CW format.
  """
  @spec collect_vhost_metrics(Keyword.t) :: List.t
  def collect_vhost_metrics(options) do
    filter = Keyword.get(options, :export_metrics, [])

    RabbitVHost.info_all()
      |> RabbitMGMTDB.augment_vhosts(Common.no_range)
      |> Enum.flat_map(&vhost_metrics/1)
      |> Common.filter_metrics(filter)
  end

  defp vhost_metrics(vhost) do
    dimensions = [{"Metric", "VHost"},
                  {"VHost", Keyword.get(vhost, :name)}]

    Common.stats(vhost, Common.message_counts)
      ++ Common.stats(Keyword.get(vhost, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
