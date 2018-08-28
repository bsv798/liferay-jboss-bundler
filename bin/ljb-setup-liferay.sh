#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$SCRIPT_DIR/ljb-setup-conf.sh"

download_files() {
	download_file "Liferay OSGi $LIFERAY_FULL_VERSION" "$LIFERAY_OSGI_DOWNLOAD_URL" "$LIFERAY_OSGI_ARCHIVE_PATH"
	download_file "Liferay Dependencies $LIFERAY_FULL_VERSION" "$LIFERAY_DEPENDENCIES_DOWNLOAD_URL" "$LIFERAY_DEPENDENCIES_ARCHIVE_PATH"
	download_file "Liferay War $LIFERAY_FULL_VERSION" "$LIFERAY_WAR_DOWNLOAD_URL" "$LIFERAY_WAR_ARCHIVE_PATH"
}

extract_files() {
	mkdir "$LIFERAY_HOME/dependencies" 2> /dev/null
	unzip -q "$LIFERAY_DEPENDENCIES_ARCHIVE_PATH" -d "$LIFERAY_HOME"
	mv "$LIFERAY_HOME/$LIFERAY_PREFIX-dependencies-$LIFERAY_SHORT_VERSION"/* "$LIFERAY_HOME/dependencies"
	rm -rf "$LIFERAY_HOME/$LIFERAY_PREFIX-dependencies-$LIFERAY_SHORT_VERSION"

	unzip -q "$LIFERAY_OSGI_ARCHIVE_PATH" -d "$LIFERAY_HOME"
	mv "$LIFERAY_HOME/$LIFERAY_PREFIX-osgi-$LIFERAY_SHORT_VERSION" "$LIFERAY_HOME/osgi"

	unzip -q "$LIFERAY_WAR_ARCHIVE_PATH" -d "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war"
	touch "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war.dodeploy"
}

setup_app_server() {
	append_to_cli "/subsystem=logging:write-attribute(name=add-logging-api-dependencies, value=false)"
	append_to_cli "/subsystem=logging:write-attribute(name=use-deployment-logging-config, value=false)"
	append_to_cli "/subsystem=logging/logger=com.google.javascript:add(level=ERROR)"

	append_to_cli "/system-property=org.apache.catalina.connector.URI_ENCODING:add(value=UTF-8)"
	append_to_cli "/system-property=org.apache.catalina.connector.USE_BODY_ENCODING_FOR_QUERY_STRING:add(value=true)"

	append_to_cli "/subsystem=deployment-scanner/scanner=default:write-attribute(name=deployment-timeout, value=600)"

	append_to_cli "/subsystem=security/security-domain=PortalRealm/:add()"
	append_to_cli "/subsystem=security/security-domain=PortalRealm/authentication=classic:add(login-modules=[{code=com.liferay.portal.security.jaas.PortalLoginModule, flag=required}])"

	append_to_cli "/subsystem=undertow/servlet-container=default/setting=jsp:write-attribute(name=development, value=true)"

	cat > "$APPSERVER_BIN_PATH/server.policy" << EOF
grant {
    permission java.security.AllPermission;
};
EOF

	local VAR1="-Xms[0-9]*[mM] -Xmx[0-9]*[mM] -XX:MetaspaceSize=[0-9]*[mM] -XX:MaxMetaspaceSize=[0-9]*[mM]"
	local VAR2="-Xmx4096m -XX:MaxMetaspaceSize=768m -XX:MetaspaceSize=384m"

	sed -i "s,$VAR1,$VAR2," "$APPSERVER_BIN_PATH/standalone.conf"

	cat >> "$APPSERVER_BIN_PATH/standalone.conf" << EOF

JAVA_OPTS="\
-Dfile.encoding=UTF-8 \
-Djava.net.preferIPv4Stack=true \
-Dsecmgr \
-Djava.security.policy='$APPSERVER_HOME_PATH/bin/server.policy' \
-Duser.timezone=GMT \
\$JAVA_OPTS"
EOF
}

setup_portal_properties() {
	cat > "$LIFERAY_HOME/portal-setup-wizard.properties" << EOF
admin.email.from.address=test@liferay.com
admin.email.from.name=Test Test
company.default.locale=en_US
company.default.web.id=liferay.com
default.admin.email.address.prefix=test
liferay.home=$LIFERAY_HOME
setup.wizard.add.sample.data=off
setup.wizard.enabled=false
EOF

	if grep -q "jdbc.default.jndi.name=java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME" "$LIFERAY_HOME/portal-ext.properties" 2> /dev/null
	then
		local VAR="\
\t<resource-ref>\n\
\t\t<res-ref-name>java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME</res-ref-name>\n\
\t\t<res-type>javax.sql.DataSource</res-type>\n\
\t\t<res-auth>Container</res-auth>\n\
\t\t<lookup-name>java:/datasources/ds_$JDBC_DRIVER_NAME</lookup-name>\n\
\t</resource-ref>\n\
</web-app>"

		sed -i "s,</web-app>,$VAR," "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/web.xml"
	fi
}

if [ "x$LIFERAY_PREFIX" != "x" ] && [ "x$LIFERAY_FULL_VERSION" != "x" ]
then
	echo "Setup Liferay"

	download_files
	extract_files
	setup_app_server
	setup_portal_properties
fi
