# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter.ExchangeMetrics do
  @moduledoc """
  Collects Exchange related metrics.
  """

  require RabbitMQCloudWatchExporter.Common

  alias :rabbit_exchange, as: RabbitExchange
  alias :rabbit_mgmt_db, as: RabbitMGMTDB
  alias :rabbit_mgmt_format, as: RabbitMGMTFormat
  alias RabbitMQCloudWatchExporter.Common, as: Common

  @type regex :: {:exchange, Regex.t}

  @doc """
  Collect Exchange metrics in AWS CW format.
  """
  @spec collect_exchange_metrics([regex]) :: List.t
  def collect_exchange_metrics(regex_patterns) do
    regex = Keyword.get(regex_patterns, :exchange, ~r/.*/)

    Common.list_vhosts()
      |> Enum.flat_map(&RabbitExchange.info_all/1)
      |> Enum.map(&RabbitMGMTFormat.exchange/1)
      |> RabbitMGMTDB.augment_exchanges(Common.no_range, :basic)
      |> Enum.filter(fn(e) -> String.match?(Keyword.get(e, :name, ""), regex) end)
      |> Enum.flat_map(&exchange_metrics/1)
  end

  defp exchange_metrics(exchange) do
    name = case Keyword.get(exchange, :name) do "" -> "_"; name -> name end
    dimensions = [{"Metric", "Exchange"},
                  {"Exchange", name},
                  {"Type", exchange |> Keyword.get(:type) |> Atom.to_string()},
                  {"VHost", Keyword.get(exchange, :vhost)}]

    Common.stats(Keyword.get(exchange, :message_stats, []), Common.message_stats)
      |> Enum.map(fn(m) -> m ++ [dimensions: dimensions] end)
  end
end
