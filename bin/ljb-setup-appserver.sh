#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$SCRIPT_DIR/ljb-setup-conf.sh"

download_files() {
	download_file "${APPSERVER_TYPE^} $APPSERVER_VERSION" "$APPSERVER_DOWNLOAD_URL" "$APPSERVER_ARCHIVE_PATH"
}

extract_files() {
	unzip -q "$APPSERVER_ARCHIVE_PATH" -d "$LIFERAY_HOME"
}

if [ "x$APPSERVER_TYPE" != "x" ] && [ "x$APPSERVER_VERSION" != "x" ] && [ "x$APPSERVER_DOWNLOAD_URL" != "x" ]
then
	echo "Setup ${APPSERVER_TYPE^}"
	
	download_files
	extract_files
fi
