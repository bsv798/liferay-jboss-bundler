#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	execute_cli
}

clean_temporary_resources() {
	rm -rf "$LIFERAY_HOME/dependencies" > /dev/null 2>&1
	rm -f "$APPSERVER_SETUP_CLI_PATH" > /dev/null 2>&1
}

setup_app_server

echo "Clean temporary resources"

clean_temporary_resources
