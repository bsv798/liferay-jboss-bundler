#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

if [ "x$LIFERAY_HOME" != "x" ]
then
	rm -rf "$LIFERAY_HOME"
	mkdir -p "$LIFERAY_HOME"
fi
