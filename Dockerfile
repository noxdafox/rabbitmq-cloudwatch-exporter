FROM rabbitmq:4.0-management-alpine

ARG CLOUDWATCH_EXPORTER_PLUGIN_VERSION=v1.0.6
ARG CLOUDWATCH_EXPORTER_PLUGIN_FLAVOR=v4.0.x-27.3.1

ENV RABBITMQ_PLUGINS_DIR=/opt/rabbitmq/plugins:/usr/lib/rabbitmq/plugins

RUN apk --no-cache add curl zip

#Install Cloudwatch rabbitmq plugin
RUN curl -L -o ./cloudwatch-exporter.zip https://github.com/ZeroGachis/rabbitmq-cloudwatch-exporter/releases/download/${CLOUDWATCH_EXPORTER_PLUGIN_VERSION}/plugins-${CLOUDWATCH_EXPORTER_PLUGIN_FLAVOR}.zip \
    && mkdir -p /usr/lib/rabbitmq/plugins \
    && unzip ./cloudwatch-exporter.zip -d /usr/lib/rabbitmq/plugins/ \
    && rm -rf cloudwatch-exporter.zip


RUN rabbitmq-plugins enable rabbitmq_cloudwatch_exporter

CMD ["rabbitmq-server"]