# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019-2025, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter do
  use Application

  @impl true
  def start(_, _) do
    children = [
      {Singleton.Supervisor, name: RabbitMQCloudWatchExporter.Singleton}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)

    Singleton.start_child(
      RabbitMQCloudWatchExporter.Singleton,
      RabbitMQCloudWatchExporter.Exporter,
      [],
      :rabbitmq_cloudwatch_exporter
    )
  end

  @impl true
  def stop(_) do
    Singleton.stop_child(
      RabbitMQCloudWatchExporter.Singleton,
      RabbitMQCloudWatchExporter.Exporter,
      []
    )
  end
end
