#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

sh "$SCRIPT_DIR/bin/ljb-setup-start.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-appserver.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jdbc.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-liferay.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jks.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-elastic.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-finish.sh"
