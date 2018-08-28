#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$SCRIPT_DIR/ljb-setup-conf.sh"

download_files() {
	download_file "JDBC Driver" "$JDBC_DRIVER_DOWNLOAD_URL" "$JDBC_DRIVER_PATH"
}

extract_files() {
	mkdir "$LIFERAY_HOME/dependencies"
	cp "$JDBC_DRIVER_PATH" "$LIFERAY_HOME/dependencies"
}

setup_app_server() {
	append_to_cli "/subsystem=elytron/credential-store=jdbc_credential_store:add(location=\"$APPSERVER_BIN_PATH/credential_store/jdbc_credential_store.jceks\", credential-reference={clear-text=\"$JDBC_CREDENTIAL_STORE_PASSWORD\"}, create=true)"
	append_to_cli "/subsystem=elytron/credential-store=jdbc_credential_store:add-alias(alias=\"$JDBC_DRIVER_NAME\", secret-value=\"$JDBC_DRIVER_PASSWORD\")"

	append_to_cli "/subsystem=datasources/jdbc-driver=\"$JDBC_DRIVER_NAME\":add(driver-name=\"$JDBC_DRIVER_NAME\",driver-module-name=com.liferay.portal)"
	append_to_cli "data-source add --name=\"ds_$JDBC_DRIVER_NAME\" --jndi-name=\"java:/datasources/ds_$JDBC_DRIVER_NAME\" --driver-name=\"$JDBC_DRIVER_NAME\" --driver-class=$JDBC_DRIVER_CLASSNAME --connection-url=\"$JDBC_DRIVER_CONNECTION_URL\" --user-name=\"$JDBC_DRIVER_USERNAME\" --credential-reference={store=jdbc_credential_store, alias=\"$JDBC_DRIVER_NAME\"}"
}

setup_portal_properties() {
	echo "jdbc.default.jndi.name=java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME" >> "$LIFERAY_HOME/portal-ext.properties"
}

if [ "x$JDBC_DRIVER_DOWNLOAD_URL" != "x" ] && [ "x$JDBC_DRIVER_CLASSNAME" != "x" ] && [ "x$JDBC_DRIVER_CONNECTION_URL" != "x" ] && [ "x$JDBC_DRIVER_USERNAME" != "x" ] && [ "x$JDBC_DRIVER_PASSWORD" != "x" ] && [ "x$JDBC_CREDENTIAL_STORE_PASSWORD" != "x" ]
then
	echo "Setup JDBC driver"

	download_files
	extract_files
	setup_app_server
	setup_portal_properties
fi
