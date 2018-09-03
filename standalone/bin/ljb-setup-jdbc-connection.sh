#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	append_to_cli "/subsystem=elytron/credential-store=jdbc_credential_store:add-alias(alias=\"$JDBC_DRIVER_NAME\", secret-value=\"$JDBC_DRIVER_PASSWORD\")"

	append_to_cli "data-source add --name=\"ds_$JDBC_DRIVER_NAME\" --jndi-name=\"java:/datasources/ds_$JDBC_DRIVER_NAME\" --driver-name=\"$JDBC_DRIVER_NAME\" --driver-class=$JDBC_DRIVER_CLASSNAME --connection-url=\"$JDBC_DRIVER_CONNECTION_URL\" --user-name=\"$JDBC_DRIVER_USERNAME\" --credential-reference={store=jdbc_credential_store, alias=\"$JDBC_DRIVER_NAME\"}"
}

setup_portal_properties() {
	echo "jdbc.default.jndi.name=java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME" >> "$APPSERVER_HOME_PATH/../portal-ext.properties"

	local VAR="\
\t<resource-ref>\n\
\t\t<res-ref-name>java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME</res-ref-name>\n\
\t\t<res-type>javax.sql.DataSource</res-type>\n\
\t\t<res-auth>Container</res-auth>\n\
\t\t<lookup-name>java:/datasources/ds_$JDBC_DRIVER_NAME</lookup-name>\n\
\t</resource-ref>\n\
</web-app>"

	sed -i "s,</web-app>,$VAR," "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/web.xml"
}

if [ "x$JDBC_DRIVER_CLASSNAME" != "x" ] && [ "x$JDBC_DRIVER_CONNECTION_URL" != "x" ] && [ "x$JDBC_DRIVER_USERNAME" != "x" ] && [ "x$JDBC_DRIVER_PASSWORD" != "x" ]
then
	echo "Setup JDBC connection"

	setup_app_server
	setup_portal_properties
fi
