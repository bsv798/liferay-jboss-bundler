#!/bin/sh

export SCRIPT_DIR="$( cd "$( dirname "$0" )" > /dev/null && pwd )"

sh "$SCRIPT_DIR/bin/ljb-setup-start.sh" true
sh "$SCRIPT_DIR/bin/ljb-setup-appserver.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jdbc-driver.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-liferay.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-liferay-cluster.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-liferay-deployment.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-prometheus.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-finish.sh"

sh "$SCRIPT_DIR/bin/ljb-setup-start.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jdbc-connection.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jks.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-elastic.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-finish.sh"
