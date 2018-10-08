#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

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

	mkdir -p "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war"
	unzip -q "$LIFERAY_WAR_ARCHIVE_PATH" -d "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war"
	touch "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war.dodeploy"
}

setup_app_server() {
	local DEP_PATH="`echo "$LIFERAY_HOME/dependencies" | sed "s/\ /\\\\\ /g"`"
	local FILES="`ls "$LIFERAY_HOME/dependencies" 2> /dev/null`"
	local FILE_STRING=

	for FILE in $FILES
	do
		FILE_STRING=$DEP_PATH/$FILE,$FILE_STRING
	done
	FILE_STRING="${FILE_STRING%?}"

	append_to_cli "module add --name=com.liferay.portal --resource-delimiter=, --resources=$FILE_STRING --dependencies=javax.api,javax.mail.api,javax.servlet.api,javax.servlet.jsp.api,javax.transaction.api,javax.xml.bind.api"

	append_to_cli "/subsystem=logging:write-attribute(name=add-logging-api-dependencies, value=false)"
	append_to_cli "/subsystem=logging:write-attribute(name=use-deployment-logging-config, value=false)"
	append_to_cli "/subsystem=logging/logger=com.google.javascript:add(level=ERROR)"

	append_to_cli "/system-property=org.apache.catalina.connector.URI_ENCODING:add(value=UTF-8)"
	append_to_cli "/system-property=org.apache.catalina.connector.USE_BODY_ENCODING_FOR_QUERY_STRING:add(value=true)"

	append_to_cli "/subsystem=deployment-scanner/scanner=default:write-attribute(name=deployment-timeout, value=600)"
	append_to_cli "/system-property=jboss.as.management.blocking.timeout:add(value=600)"

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

	cat > "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/classes/portal-ext.properties" << EOF
include-and-override=$LIFERAY_HOME/portal-ext.properties
include-and-override=$LIFERAY_HOME/portal-setup-wizard.properties
EOF
}

update_checksum() {
	local KEY
	local VALUE

	for i in $(echo "$LIFERAY_PACKAGE_CHECKSUM" | sed "s/,/ /g")
	do
		KEY=`echo $i | cut -f1 -d =`
		VALUE=`echo $i | cut -f2 -d =`

		sed -i "s,$KEY=.*,$KEY=$VALUE," "$LIFERAY_HOME/osgi/target-platform/integrity.properties"
	done
}

turn_off_logging() {
	if [ "x$LIFERAY_TURN_OFF_LOGGING" = "xtrue" ]
	then
		local EXTRACT_PATH="$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/classes/META-INF"
		local SOURCE_FILE="portal-log4j.xml"
		local DESTINATION_FILE="portal-log4j-ext.xml"

		unzip -q -j "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/lib/portal-impl.jar" "META-INF/$SOURCE_FILE" -d "$EXTRACT_PATH"
		mv "$EXTRACT_PATH/$SOURCE_FILE" "$EXTRACT_PATH/$DESTINATION_FILE"

		sed -i "s,.*<appender-ref ref=\"XML_FILE\" />,," "$EXTRACT_PATH/$DESTINATION_FILE"
		sed -i "s,.*<appender-ref ref=\"TEXT_FILE\" />,," "$EXTRACT_PATH/$DESTINATION_FILE"
	fi
}

if [ "x$LIFERAY_PREFIX" != "x" ] && [ "x$LIFERAY_FULL_VERSION" != "x" ]
then
	echo "Setup Liferay"

	if [ "x$LIFERAY_BASE_URL" != "x" ]
	then
		download_files
		extract_files
	fi
	setup_app_server
	setup_portal_properties
	update_checksum
	turn_off_logging
fi
