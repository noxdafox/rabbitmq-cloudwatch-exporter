# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019-2020, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQCloudWatchExporter do
  use Application

  def start(_type, _args) do
    Singleton.start_child(
      RabbitMQCloudWatchExporter.Exporter, [], :rabbitmq_cloudwatch_exporter)
  end
end
