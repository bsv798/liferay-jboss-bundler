#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

download_files() {
	download_file "$APPSERVER_NAME $APPSERVER_VERSION" "$APPSERVER_DOWNLOAD_URL" "$APPSERVER_ARCHIVE_PATH"
}

extract_files() {
	unzip -q "$APPSERVER_ARCHIVE_PATH" -d "$APPSERVER_HOME_PATH"
	mv "$APPSERVER_HOME_PATH/$APPSERVER_TYPE-$APPSERVER_VERSION"/* "$APPSERVER_HOME_PATH"
	mv "$APPSERVER_HOME_PATH/$APPSERVER_TYPE-$APPSERVER_VERSION"/.??* "$APPSERVER_HOME_PATH"
	rm -rf "$APPSERVER_HOME_PATH/$APPSERVER_TYPE-$APPSERVER_VERSION"
}

turn_off_logging() {
	if [ "x$APPSERVER_TURN_OFF_LOGGING" = "xtrue" ]
	then
		append_to_cli "/subsystem=logging/root-logger=ROOT:remove-handler(name=FILE)"
	fi
}

if [ "x$APPSERVER_TYPE" != "x" ] && [ "x$APPSERVER_VERSION" != "x" ]
then
	APPSERVER_NAME="$(echo "$APPSERVER_TYPE" | sed 's/.*/\u&/')"

	echo "Setup $APPSERVER_NAME"
	
	if [ "x$APPSERVER_DOWNLOAD_URL" != "x" ]
	then
		download_files
		extract_files
	fi
	turn_off_logging
fi
