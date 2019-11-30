# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.OverviewMetrics do
  @moduledoc """
  Collects general overview metrics.
  """

  require RabbitMQCloudWatchExporter.Common

  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQCloudWatchExporter.Common, as: Common

  @type regex :: {Atom.t, Regex.t}

  @doc """
  Collect overview metrics in AWS CW format.
  """
  @spec collect_overview_metrics([regex]) :: List.t
  def collect_overview_metrics(_regex_patterns) do
    RabbitMGMTDB.get_overview(Common.no_range) |> overview_metrics()
  end

  defp overview_metrics(overview) do
    dimensions = [{"Metric", "ClusterOverview"}]

    Common.stats(Keyword.get(overview, :queue_totals, []), Common.message_counts)
      ++ Common.stats(Keyword.get(overview, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
