#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

if [ "x$APPSERVER_HOME_PATH" != "x" ]
then
	if [ "$1" == "true" ]
	then
		rm -rf "$APPSERVER_HOME_PATH"
	fi
	mkdir -p "$APPSERVER_HOME_PATH"
fi

if [ "x$LIFERAY_HOME" != "x" ]
then
	if [ "$1" == "true" ]
	then
		rm -rf "$LIFERAY_HOME"
	fi
	mkdir -p "$LIFERAY_HOME"
fi
