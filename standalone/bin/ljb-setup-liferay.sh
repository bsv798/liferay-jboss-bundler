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

copy_additional_dependencies() {
	if [ "x$LIFERAY_ADDITIONAL_DEPENDENCIES_PATH" != "x" ] && [ -d "$LIFERAY_ADDITIONAL_DEPENDENCIES_PATH" ] && [ "`ls -1q \"$LIFERAY_ADDITIONAL_DEPENDENCIES_PATH\" | wc -l`" -gt "0" ]
	then
		cp "${LIFERAY_ADDITIONAL_DEPENDENCIES_PATH}"/* "$LIFERAY_HOME/dependencies"
	fi
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

	append_to_cli "/subsystem=logging:write-attribute(name=add-logging-api-dependencies, value=true)"
	append_to_cli "/subsystem=logging:write-attribute(name=use-deployment-logging-config, value=false)"
	append_to_cli "/subsystem=logging/console-handler=CONSOLE:write-attribute(name=level, value=ALL)"
	append_to_cli "/subsystem=logging/logger=com.google.javascript:add(level=ERROR)"
	append_to_cli "/subsystem=logging/logger=osgi.logging.org_apache_felix_scr:add(level=ERROR)"

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

	local MEM_LINE_NUMBER=`grep -n 'PRESERVE_JAVA_OPTS' "$APPSERVER_BIN_PATH/standalone.conf" | cut -d: -f 1`
	local MEM_TEXT="\
LIFERAY_MIN_MEMORY=\\\"\\\${LIFERAY_MIN_MEMORY:-2048m}\\\"\n\
LIFERAY_MAX_MEMORY=\\\"\\\${LIFERAY_MAX_MEMORY:-4096m}\\\"\n\
LIFERAY_MIN_METASPACE=\\\"\\\${LIFERAY_MIN_METASPACE:-384m}\\\"\n\
LIFERAY_MAX_METASPACE=\\\"\\\${LIFERAY_MAX_METASPACE:-768m}\\\"\n"

	sed -i "`expr ${MEM_LINE_NUMBER} + 1`a$MEM_TEXT" "$APPSERVER_BIN_PATH/standalone.conf"

	local VAR1="-Xms[0-9]*[mM] -Xmx[0-9]*[mM] -XX:MetaspaceSize=[0-9]*[mM] -XX:MaxMetaspaceSize=[0-9]*[mM]"
	local VAR2="-Xms\$LIFERAY_MIN_MEMORY -Xmx\$LIFERAY_MAX_MEMORY -XX:MaxMetaspaceSize=\$LIFERAY_MAX_METASPACE -XX:MetaspaceSize=\$LIFERAY_MIN_METASPACE"

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
include-and-override=$LIFERAY_HOME/portal-ext-bundle.properties
include-and-override=$LIFERAY_HOME/config/portal-ext.properties
include-and-override=$LIFERAY_HOME/portal-setup-wizard.properties
EOF

	mkdir -p "$LIFERAY_HOME/config"
	touch "$LIFERAY_HOME/config/portal-ext.properties"

	if [ -f "$TEMP_PATH/portal-ext.properties" ]
	then
		cat "$TEMP_PATH/portal-ext.properties" >> "$LIFERAY_HOME/portal-ext-bundle.properties"
	fi
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

copy_osgi() {
	if [ "x$LIFERAY_COPY_OSGI_PATH" != "x" ]
	then
		cp -r "$LIFERAY_COPY_OSGI_PATH"/* "$LIFERAY_OSGI_PATH"
	fi
}

turn_off_logging() {
	if [ "x$LIFERAY_TURN_OFF_LOGGING" = "xtrue" ]
	then
		local PORTAL_IMPL_JAR="$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/lib/portal-impl.jar"
		local EXTRACT_PATH="$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF"
		local SOURCE_FILE="portal-log4j.xml"
		local LOG_ENTRIES

		unzip -q -j "$PORTAL_IMPL_JAR" "META-INF/$SOURCE_FILE" -d "$EXTRACT_PATH"

		LOG_ENTRIES=`xmlstarlet fo -D "$EXTRACT_PATH/$SOURCE_FILE" | xmlstarlet sel -t -m "/log4j:configuration/category" -v "concat('/subsystem=logging/logger=',@name,':add(level=',normalize-space(priority/@value),')')" -n`
		for LOG_ENTRY in $LOG_ENTRIES
		do
			append_to_cli "$LOG_ENTRY"
		done
		append_to_cli "/subsystem=logging/pattern-formatter=COLOR-PATTERN:write-attribute(name=pattern, value=%d{yyyy-MM-dd HH:mm:ss.SSS}  %-5p [%t][%c:%L] %m%n)"
		append_to_cli "/subsystem=logging/console-handler=JUST-PRINT:add(formatter=%m%n)"
		append_to_cli "/subsystem=logging/logger=stderr:add(use-parent-handlers=false, handlers=[JUST-PRINT])"
		append_to_cli "/subsystem=logging/logger=stdout:add(use-parent-handlers=false, handlers=[JUST-PRINT])"

		rm "$EXTRACT_PATH/$SOURCE_FILE"
		zip -q -d "$PORTAL_IMPL_JAR" "META-INF/$SOURCE_FILE"

		xmlstarlet ed -L -N x="urn:jboss:deployment-structure:1.1" -d "/x:jboss-deployment-structure/x:deployment/x:exclusions/x:module[@name='org.apache.log4j']" "$EXTRACT_PATH/jboss-deployment-structure.xml"
		xmlstarlet ed -L -N x="urn:jboss:deployment-structure:1.1" -d "/x:jboss-deployment-structure/x:deployment/x:exclusions/x:module[@name='org.slf4j']" "$EXTRACT_PATH/jboss-deployment-structure.xml"
	fi
}

setup_libre_office() {
	if [ "x$LIBREOFFICE_SERVER_HOST" != "x" ] && [ "x$LIBREOFFICE_SERVER_PORT" != "x" ]
	then
		cat > "$LIFERAY_HOME/osgi/configs/com.liferay.document.library.document.conversion.internal.configuration.OpenOfficeConfiguration.config" << EOF
serverEnabled="true"
serverHost="$LIBREOFFICE_SERVER_HOST"
serverPort="$LIBREOFFICE_SERVER_PORT"
EOF
	fi
}

if [ "x$LIFERAY_PREFIX" != "x" ] && [ "x$LIFERAY_FULL_VERSION" != "x" ]
then
	echo "Setup Liferay"

	if [ "x$LIFERAY_BASE_URL" != "x" ]
	then
		download_files
		extract_files
		copy_additional_dependencies
	fi
	setup_app_server
	setup_portal_properties
	update_checksum
	copy_osgi
	turn_off_logging
	setup_libre_office
fi
