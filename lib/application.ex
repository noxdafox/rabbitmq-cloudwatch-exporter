# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2019, Matteo Cafasso.
# All rights reserved.

defmodule RabbitMQ.CloudWatchExporter.Application do
  use Application

  def start(_type, _args) do
    children = [RabbitMQ.CloudWatchExporter.Exporter]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
