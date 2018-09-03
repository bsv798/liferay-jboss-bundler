#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

if [ "x$LIFERAY_HOME" != "x" ]
then
	if [ "$1" == "true" ]
	then
		rm -rf "$LIFERAY_HOME"
	fi
	mkdir -p "$LIFERAY_HOME"
fi
