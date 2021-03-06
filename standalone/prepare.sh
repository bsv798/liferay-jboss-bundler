#!/bin/sh

export SCRIPT_DIR="$( cd "$( dirname "$0" )" > /dev/null && pwd )"

sh "$SCRIPT_DIR/bin/ljb-setup-start.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jdbc-connection.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-mail-cred.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-jks.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-elastic.sh"
sh "$SCRIPT_DIR/bin/ljb-setup-finish.sh" "prepare"
