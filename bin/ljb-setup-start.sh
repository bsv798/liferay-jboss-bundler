#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$SCRIPT_DIR/ljb-setup-conf.sh"

rm -rf "$LIFERAY_HOME"
