#!/bin/sh

TEMP_PATH="$SCRIPT_DIR/t m p"

source "$SCRIPT_DIR/bin/ljb.conf"

LIFERAY_SHORT_VERSION=`echo "$LIFERAY_FULL_VERSION" | sed "s/\(.*\)-.*./\1/"`
LIFERAY_BASE_URL="$LIFERAY_BASE_URL/$LIFERAY_PREFIX!!!-$LIFERAY_FULL_VERSION"
LIFERAY_OSGI_DOWNLOAD_URL="`echo "$LIFERAY_BASE_URL" | sed "s/!!!/-osgi/"`.zip"
LIFERAY_OSGI_ARCHIVE_PATH=$TEMP_PATH/liferay-osgi.zip
LIFERAY_DEPENDENCIES_DOWNLOAD_URL="`echo "$LIFERAY_BASE_URL" | sed "s/!!!/-dependencies/"`.zip"
LIFERAY_DEPENDENCIES_ARCHIVE_PATH=$TEMP_PATH/liferay-dependencies.zip
LIFERAY_WAR_DOWNLOAD_URL="`echo "$LIFERAY_BASE_URL" | sed "s/!!!//"`.war"
LIFERAY_WAR_ARCHIVE_PATH=$TEMP_PATH/liferay-portal.war

APPSERVER_VERSION=`if [ "$APPSERVER_TYPE" = "jboss-eap" ]; then echo "$APPSERVER_VERSION" | sed "s/\([0-9]*\.[0-9]*\).*/\1/"; else echo "$APPSERVER_VERSION"; fi`
APPSERVER_ARCHIVE_PATH=$TEMP_PATH/$APPSERVER_TYPE.zip

APPSERVER_HOME_PATH=$LIFERAY_HOME/$APPSERVER_TYPE-$APPSERVER_VERSION
APPSERVER_BIN_PATH=$APPSERVER_HOME_PATH/bin
APPSERVER_CLI_PATH=$APPSERVER_BIN_PATH/jboss-cli.sh
APPSERVER_DEPLOYMENTS_PATH=$APPSERVER_HOME_PATH/standalone/deployments
APPSERVER_SETUP_CLI_PATH=$LIFERAY_HOME/setup.cli

JDBC_DRIVER_NAME=`basename -- "$JDBC_DRIVER_DOWNLOAD_URL"`
JDBC_DRIVER_PATH=$TEMP_PATH/$JDBC_DRIVER_NAME

download_file() {
	local NAME=$1
	local URL=`echo "$2" | sed "s/\ /%20/g"`
	local OUTPUT=$3

	if [ -f "$OUTPUT" ]
	then
		echo "Using previously downloaded file $OUTPUT"
	else
		echo "Downloading $NAME from $URL"
		curl --silent --location --create-dirs --output "$OUTPUT" "$URL"
	fi
}

append_to_cli() {
	local TEXT=$1

	if [ ! -f "$APPSERVER_SETUP_CLI_PATH" ]
	then
		echo "embed-server" >> "$APPSERVER_SETUP_CLI_PATH"
		echo "batch" >> "$APPSERVER_SETUP_CLI_PATH"
	fi
	echo "$TEXT" >> "$APPSERVER_SETUP_CLI_PATH"
}

execute_cli() {
	if [ -f "$APPSERVER_SETUP_CLI_PATH" ]
	then
		echo "run-batch" >> "$APPSERVER_SETUP_CLI_PATH"

		"$APPSERVER_CLI_PATH" --file="$APPSERVER_SETUP_CLI_PATH"
	fi
}
