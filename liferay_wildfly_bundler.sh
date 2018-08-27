#!/bin/sh

download() {
	local NAME=$1
	local URL=`echo "$2" | sed "s/\ /%20/g"`
	local OUTPUT=$3

	if [ -f "$OUTPUT" ]
	then
		echo "Using previously downloaded file $OUTPUT"
	else
		echo "Downloading $NAME from $URL"
		curl --location --create-dirs --output "$OUTPUT" "$URL"
	fi
}

download_files() {
	download "Wildfly $APPSERVER_VERSION" "$APPSERVER_DOWNLOAD_URL" "$APPSERVER_ARCHIVE_PATH"
	download "Liferay OSGi $LIFERAY_FULL_VERSION" "$LIFERAY_OSGI_DOWNLOAD_URL" "$LIFERAY_OSGI_ARCHIVE_PATH"
	download "Liferay Dependencies $LIFERAY_FULL_VERSION" "$LIFERAY_DEPENDENCIES_DOWNLOAD_URL" "$LIFERAY_DEPENDENCIES_ARCHIVE_PATH"
	download "Liferay War $LIFERAY_FULL_VERSION" "$LIFERAY_WAR_DOWNLOAD_URL" "$LIFERAY_WAR_ARCHIVE_PATH"
	download "JDBC Driver" "$JDBC_DRIVER_DOWNLOAD_URL" "$JDBC_DRIVER_PATH"
}

extract_files() {
	echo "Extract files"

	rm -rf "$LIFERAY_HOME"
	unzip -q "$APPSERVER_ARCHIVE_PATH" -d "$LIFERAY_HOME"
	unzip -q "$LIFERAY_DEPENDENCIES_ARCHIVE_PATH" -d "$LIFERAY_HOME"
	mv "$LIFERAY_HOME/$LIFERAY_PREFIX-dependencies-$LIFERAY_SHORT_VERSION" "$LIFERAY_HOME/dependencies"
	unzip -q "$LIFERAY_OSGI_ARCHIVE_PATH" -d "$LIFERAY_HOME"
	mv "$LIFERAY_HOME/$LIFERAY_PREFIX-osgi-$LIFERAY_SHORT_VERSION" "$LIFERAY_HOME/osgi"
	unzip -q "$LIFERAY_WAR_ARCHIVE_PATH" -d "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war"
	touch "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war.dodeploy"

	cp "$JDBC_DRIVER_PATH" "$LIFERAY_HOME/dependencies"

	mkdir "$(dirname "$JKS_SERVER_FILE_PATH")"
	cp "$JKS_LOCAL_FILE_PATH" "$JKS_SERVER_FILE_PATH"
}

setup_app_server() {
	echo "Setup application server"

	local DEP_PATH=`echo "$LIFERAY_HOME/dependencies" | sed "s/\ /\\\\\ /g"`
	local FILE_LIST=(`ls -p "$LIFERAY_HOME/dependencies" | grep -v / | tr '\n' ' '`)
	local FILE_LEN=${#FILE_LIST[@]}
	local FILE_STRING=$DEP_PATH/${FILE_LIST[0]}

	for (( i = 1; i < $FILE_LEN; i++ )); do
	    local FILE=${FILE_LIST[$i]}

	    FILE_STRING=$FILE_STRING,$DEP_PATH/$FILE
	done

	cat > "$APPSERVER_SETUP_CLI_PATH" << EOF
embed-server

batch

/subsystem=logging:write-attribute(name=add-logging-api-dependencies, value=false)
/subsystem=logging:write-attribute(name=use-deployment-logging-config, value=false)
/subsystem=logging/logger=com.google.javascript:add(level=ERROR)

module add --name=com.liferay.portal --resource-delimiter=, --resources=$FILE_STRING --dependencies=javax.api,javax.mail.api,javax.servlet.api,javax.servlet.jsp.api,javax.transaction.api,javax.xml.bind.api

/system-property="org.apache.catalina.connector.URI_ENCODING":add(value="UTF-8")
/system-property="org.apache.catalina.connector.USE_BODY_ENCODING_FOR_QUERY_STRING":add(value="true")

/subsystem=deployment-scanner/scanner=default:write-attribute(name="deployment-timeout", value="600")

/subsystem=security/security-domain="PortalRealm"/:add()
/subsystem=security/security-domain="PortalRealm"/authentication=classic:add(login-modules=[{code="com.liferay.portal.security.jaas.PortalLoginModule", flag="required"}])

/subsystem=undertow/servlet-container=default/setting=jsp:write-attribute(name="development", value="true")

/subsystem=elytron/credential-store=jdbc_credential_store:add(location="$APPSERVER_BIN_PATH/credential_store/jdbc_credential_store.jceks", credential-reference={clear-text="$JDBC_CREDENTIAL_STORE_PASSWORD"}, create=true)
/subsystem=elytron/credential-store=jdbc_credential_store:add-alias(alias="$JDBC_DRIVER_NAME", secret-value="$JDBC_DRIVER_PASSWORD")

/subsystem=datasources/jdbc-driver="$JDBC_DRIVER_NAME":add(driver-name="$JDBC_DRIVER_NAME",driver-module-name=com.liferay.portal)
data-source add --name="ds_$JDBC_DRIVER_NAME" --jndi-name="java:/datasources/ds_$JDBC_DRIVER_NAME" --driver-name="$JDBC_DRIVER_NAME" --driver-class=$JDBC_DRIVER_CLASSNAME --connection-url="$JDBC_DRIVER_CONNECTION_URL" --user-name="$JDBC_DRIVER_USERNAME" --credential-reference={store=jdbc_credential_store, alias="$JDBC_DRIVER_NAME"}

/subsystem=elytron/key-store=server_key_store:add(path="$JKS_SERVER_FILE_PATH", credential-reference={clear-text="$JKS_STORE_PASSWORD"}, type=JKS)
/subsystem=elytron/key-manager=server_key_manager:add(key-store=server_key_store, credential-reference={clear-text="$JKS_KEY_PASSWORD"})
/subsystem=elytron/server-ssl-context=server_key_ssl_context:add(key-manager=server_key_manager, protocols=["TLSv1.2"])

/subsystem=undertow/server=default-server/https-listener=https:undefine-attribute(name=security-realm)
/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=ssl-context, value=server_key_ssl_context)

run-batch
EOF

	"$APPSERVER_CLI_PATH" --file="$APPSERVER_SETUP_CLI_PATH"

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
	echo "Setup portal properties"

	echo "jdbc.default.jndi.name=java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME" > "$LIFERAY_HOME/portal-ext.properties"

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

	local VAR="\
\t<resource-ref>\n\
\t\t<res-ref-name>java:comp/env/jdbc/ds_$JDBC_DRIVER_NAME</res-ref-name>\n\
\t\t<res-type>javax.sql.DataSource</res-type>\n\
\t\t<res-auth>Container</res-auth>\n\
\t\t<lookup-name>java:/datasources/ds_$JDBC_DRIVER_NAME</lookup-name>\n\
\t</resource-ref>\n\
</web-app>"

	sed -i "s,</web-app>,$VAR," "$APPSERVER_DEPLOYMENTS_PATH/ROOT.war/WEB-INF/web.xml"

	cat > "$LIFERAY_HOME/osgi/configs/com.liferay.portal.search.elasticsearch.configuration.ElasticsearchConfiguration.cfg" << EOF
operationMode=REMOTE
transportAddresses=$ELASTIC_TRANSPORT_ADDRESSES
clusterName=$ELASTIC_CLUSTER_NAME
logExceptionsOnly=true
EOF
}

clean_temporary_resources() {
	echo "Clean temporary resources"

	rm -rf "$LIFERAY_HOME/dependencies"
}


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
TEMP_PATH="$SCRIPT_DIR/t m p"

LIFERAY_PREFIX=liferay-ce-portal
LIFERAY_FULL_VERSION=7.1.0-ga1-20180703012531655
LIFERAY_SHORT_VERSION=`echo "$LIFERAY_FULL_VERSION" | sed "s/\(.*\)-.*./\1/"`
LIFERAY_BASE_URL="https://sourceforge.net/projects/lportal/files/Liferay Portal/`echo "$LIFERAY_SHORT_VERSION" | sed "s/\(.*\)/\U\1/" | sed "s/\-/\ /"`/$LIFERAY_PREFIX!!!-$LIFERAY_FULL_VERSION"
LIFERAY_OSGI_DOWNLOAD_URL="`echo "$LIFERAY_BASE_URL" | sed "s/!!!/-osgi/"`.zip"
LIFERAY_OSGI_ARCHIVE_PATH=$TEMP_PATH/liferay-osgi.zip
LIFERAY_DEPENDENCIES_DOWNLOAD_URL="`echo "$LIFERAY_BASE_URL" | sed "s/!!!/-dependencies/"`.zip"
LIFERAY_DEPENDENCIES_ARCHIVE_PATH=$TEMP_PATH/liferay-dependencies.zip
LIFERAY_WAR_DOWNLOAD_URL="`echo "$LIFERAY_BASE_URL" | sed "s/!!!//"`.war"
LIFERAY_WAR_ARCHIVE_PATH=$TEMP_PATH/liferay-portal.war

LIFERAY_HOME=$TEMP_PATH/liferay

APPSERVER_TYPE=wildfly
#APPSERVER_TYPE=jboss-eap
APPSERVER_VERSION=13.0.0.Final
#APPSERVER_VERSION=7.1.0
APPSERVER_VERSION=`if [ "$APPSERVER_TYPE" = "jboss-eap" ]; then echo "$APPSERVER_VERSION" | sed "s/\([0-9]*\.[0-9]*\).*/\1/"; else echo "$APPSERVER_VERSION"; fi`
APPSERVER_DOWNLOAD_URL=http://download.jboss.org/$APPSERVER_TYPE/$APPSERVER_VERSION/$APPSERVER_TYPE-$APPSERVER_VERSION.zip
APPSERVER_ARCHIVE_PATH=$TEMP_PATH/$APPSERVER_TYPE.zip

APPSERVER_HOME_PATH=$LIFERAY_HOME/$APPSERVER_TYPE-$APPSERVER_VERSION
APPSERVER_BIN_PATH=$APPSERVER_HOME_PATH/bin
APPSERVER_CLI_PATH=$APPSERVER_BIN_PATH/jboss-cli.sh
APPSERVER_DEPLOYMENTS_PATH=$APPSERVER_HOME_PATH/standalone/deployments
APPSERVER_SETUP_CLI_PATH=$TEMP_PATH/setup.cli

JDBC_DRIVER_DOWNLOAD_URL="https://jdbc.postgresql.org/download/postgresql-42.2.4.jar"
JDBC_DRIVER_NAME=`basename -- "$JDBC_DRIVER_DOWNLOAD_URL"`
JDBC_DRIVER_PATH=$TEMP_PATH/$JDBC_DRIVER_NAME
JDBC_DRIVER_CLASSNAME="org.postgresql.Driver"
JDBC_DRIVER_CONNECTION_URL="jdbc:postgresql:ddd"
JDBC_DRIVER_USERNAME="postgres"
JDBC_DRIVER_PASSWORD="postgres"
JDBC_CREDENTIAL_STORE_PASSWORD="cs_pass"

JKS_LOCAL_FILE_PATH=$SCRIPT_DIR/server.keystore
JKS_SERVER_FILE_PATH=$APPSERVER_BIN_PATH/key_store/server.keystore
JKS_STORE_PASSWORD=change_store_pass
JKS_KEY_PASSWORD=change_key_pass

ELASTIC_TRANSPORT_ADDRESSES=127.0.0.1:9300
ELASTIC_CLUSTER_NAME=clustery_mcclusterface

download_files
extract_files
setup_app_server
setup_portal_properties
clean_temporary_resources
