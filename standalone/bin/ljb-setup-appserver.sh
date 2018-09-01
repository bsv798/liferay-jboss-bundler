#!/bin/sh

source "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

download_files() {
	download_file "$APPSERVER_NAME $APPSERVER_VERSION" "$APPSERVER_DOWNLOAD_URL" "$APPSERVER_ARCHIVE_PATH"
}

extract_files() {
	unzip -q "$APPSERVER_ARCHIVE_PATH" -d "$LIFERAY_HOME"
}

if [ "x$APPSERVER_TYPE" != "x" ] && [ "x$APPSERVER_VERSION" != "x" ] && [ "x$APPSERVER_DOWNLOAD_URL" != "x" ]
then
	APPSERVER_NAME=`echo ${APPSERVER_TYPE:0:1} | tr  '[a-z]' '[A-Z]'`${APPSERVER_TYPE:1}

	echo "Setup $APPSERVER_NAME"
	
	download_files
	extract_files
fi
