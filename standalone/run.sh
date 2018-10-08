#!/bin/sh

export SCRIPT_DIR="$( cd "$( dirname "$0" )" > /dev/null && pwd )"

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

exec "$APPSERVER_HOME_PATH/bin/standalone.sh" "-b" "0.0.0.0" "$@"
