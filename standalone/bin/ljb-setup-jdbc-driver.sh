#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

download_files() {
	download_file "JDBC Driver" "$JDBC_DRIVER_DOWNLOAD_URL" "$JDBC_DRIVER_PATH"
}

extract_files() {
	mkdir "$LIFERAY_HOME/dependencies"
	cp "$JDBC_DRIVER_PATH" "$LIFERAY_HOME/dependencies"
}

setup_app_server() {
	append_to_cli "/subsystem=datasources/jdbc-driver=\"$JDBC_DRIVER_NAME\":add(driver-name=\"$JDBC_DRIVER_NAME\",driver-module-name=com.liferay.portal)"

	append_to_cli "/subsystem=elytron/credential-store=jdbc_credential_store:add(location=\"$APPSERVER_BIN_PATH/credential_store/jdbc_credential_store.jceks\", credential-reference={clear-text=\"$JDBC_CREDENTIAL_STORE_PASSWORD\"}, create=true)"
}

if [ "x$JDBC_CREDENTIAL_STORE_PASSWORD" != "x" ]
then
	echo "Setup JDBC driver"

	if [ "x$JDBC_DRIVER_DOWNLOAD_URL" != "x" ]
	then
		download_files
		extract_files
	fi
	setup_app_server
fi
