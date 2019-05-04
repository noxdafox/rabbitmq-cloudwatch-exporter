# RabbitMQ AWS CloudWatch exporter

A plugin for exporting the metrics collected by the RabbitMQ Management Plugin to [AWS CloudWatch](https://aws.amazon.com/cloudwatch/).

## Installing

Download the `.ez` files from the latest [release](https://github.com/noxdafox/rabbitmq-cloudwatch-exporter/releases) and copy them into the [RabbitMQ plugins directory](http://www.rabbitmq.com/relocate.html).

Enable the plugin:

```bash
    [sudo] rabbitmq-plugins enable rabbitmq_cloudwatch_exporter
```

## Building from Source

Please see RabbitMQ Plugin Development guide.

To build the plugin:

```bash
    git clone https://github.com/noxdafox/rabbitmq-cloudwatch-exporter.git
    cd rabbitmq-cloudwatch-exporter
    make dist
```

Then copy all the *.ez files inside the plugins folder to the [RabbitMQ plugins directory](http://www.rabbitmq.com/relocate.html) and enable the plugin:

```bash
    [sudo] rabbitmq-plugins enable rabbitmq_cloudwatch_exporter
```

## Configuration

### AWS Credentials

To resolve AWS credentials, the standard environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are looked up first. Otherwise, the EC2 instance role or ECS task role are employed.

Alternatively, the User can specify them in the `rabbitmq.conf` file as follows.

```shell
    cloudwatch_exporter.aws.access_key_id = "AKIAIOSFODNN7EXAMPLE"
    cloudwatch_exporter.aws.secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

Or in the `rabbitmq.config` format.

```erlang
    [{ex_aws, [{access_key_id, "AKIAIOSFODNN7EXAMPLE"},
               {secret_access_key, "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}]}].
```

### AWS Region

By default the metrics are published within the `us-east-1` AWS region. The region can be changed in the `rabbitmq.conf` file as follows.

```shell
    cloudwatch_exporter.aws.region = "us-west-1"
```

Or in the `rabbitmq.config` format.

```erlang
    [{ex_aws, [{region, "us-west-1"}]}].
```

### Metrics collection

Metrics are grouped in different categories described below. Each category must be enabled in the configuration in order for its metrics to be exported.

`rabbitmq.conf` example.

```shell
    cloudwatch_exporter.metrics.1 = overview
    cloudwatch_exporter.metrics.2 = vhost
    cloudwatch_exporter.metrics.3 = node
```

`rabbitmq.config` example.

```erlang
    [{rabbitmq_cloudwatch_exporter, [
      {metrics, [overview, vhost, node, exchange, queue, connection, channel]}]}].
```

Metrics are exported every minute. The export period can be expressed in seconds via the `cloudwatch_exporter.export_period` configuration parameter (`rabbitmq_cloudwatch_exporter.export_period` in `rabbitmq.config` format).

Lastly, the [AWS CloudWatch namespace](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#Namespace) can be controlled via the `cloudwatch_exporter.namespace` configuration parameter (`rabbitmq_cloudwatch_exporter.namespace` in `rabbitmq.config` format). The default value is `RabbitMQ`.

## Metrics

TODO
