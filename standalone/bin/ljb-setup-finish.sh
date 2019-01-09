#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	execute_cli "$APPSERVER_SETUP_CLI_PATH" "true"
}

setup_app_server_additional() {
	local FINISH_PHASE="$1"
	local ADDITIONAL_CLI_PATH=

	case $FINISH_PHASE in
		build )
			ADDITIONAL_CLI_PATH="$APPSERVER_AFTER_BUILD_CLI_PATH"
			;;
		prepare )
			ADDITIONAL_CLI_PATH="$APPSERVER_AFTER_PREPARE_CLI_PATH"
			;;
	esac

	execute_cli "$ADDITIONAL_CLI_PATH" "false"
}

clean_temporary_resources() {
	rm -rf "$LIFERAY_HOME/dependencies" > /dev/null 2>&1
	rm -f "$APPSERVER_SETUP_CLI_PATH" > /dev/null 2>&1
}

setup_app_server
setup_app_server_additional "$1"

echo "Clean temporary resources"

clean_temporary_resources
