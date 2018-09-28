#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

if [ "x$APPSERVER_HOME_PATH" != "x" ]
then
	if [ "x$1" = "xtrue" ]
	then
		rm -rf "$APPSERVER_HOME_PATH"
	fi
	mkdir -p "$APPSERVER_HOME_PATH"
fi

if [ "x$LIFERAY_HOME" != "x" ]
then
	if [ "x$1" = "xtrue" ]
	then
		rm -rf "$LIFERAY_HOME"
	fi
	mkdir -p "$LIFERAY_HOME"
fi
