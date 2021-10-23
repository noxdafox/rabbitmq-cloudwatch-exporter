# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019-2021, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.ChannelMetrics do
  @moduledoc """
  Collects Channel related metrics.
  """

  require RabbitMQCloudWatchExporter.Common

  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias RabbitMQCloudWatchExporter.Common, as: Common

  @type regex :: {:channel, Regex.t}

  @doc """
  Collect Channel metrics in AWS CW format.
  """
  @spec collect_channel_metrics(Keyword.t) :: List.t
  def collect_channel_metrics(options) do
    regex = Keyword.get(options, :export_regex, ~r/.*/)
    filter = Keyword.get(options, :export_metrics, [])

    RabbitMGMTDB.get_all_channels(Common.no_range)
      |> Enum.filter(fn(c) -> String.match?(Keyword.get(c, :name, ""), regex) end)
      |> Enum.flat_map(&channel_metrics/1)
      |> Common.filter_metrics(filter)
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
      ++ Common.stats(Keyword.get(channel, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
