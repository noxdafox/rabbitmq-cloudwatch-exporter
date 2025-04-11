PROJECT = rabbitmq_cloudwatch_exporter
PROJ_VSN = $(shell $(MIX) eval 'Mix.Project.config()[:version] |> IO.puts()')

DEPS = rabbit_common rabbit rabbitmq_management rabbitmq_management_agent lager_cloudwatch
dep_lager_cloudwatch = hex 0.1.2

DEP_PLUGINS = rabbit_common/mk/rabbitmq-plugin.mk
DEP_EARLY_PLUGINS = rabbit_common/mk/rabbitmq-early-plugin.mk

# Mix customizations
MIX_ENV      ?= dev
override MIX := mix
elixir_srcs  := mix.exs

# RMQ `dist` target removes anything within the `plugins` folder
# which is not managed by erlang.mk.
# We need to instruct the `rabbitmq-dist:do-dist` target to not
# remove our plugin and related dependencies.
EXTRA_DIST_EZS = $(shell find $(DIST_DIR) -name *.ez)

app:: $(elixir_srcs) deps
	$(MIX) make_app

dist:: app
	mkdir -p $(DIST_DIR)
	$(MIX) make_archives

clean::
	@rm -fr _build

include rabbitmq-components.mk
include erlang.mk
