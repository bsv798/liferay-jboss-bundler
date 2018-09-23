#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

download_files() {
	download_file "Prometheus JMX Exporter" "$PROMETHEUS_DOWNLOAD_URL" "$PROMETHEUS_COPY_LIBRARY_PATH"
}

copy_files() {
	mkdir -p "$PROMETHEUS_PATH"
	cp "$PROMETHEUS_COPY_LIBRARY_PATH" "$PROMETHEUS_LIBRARY_PATH"
	cp "$PROMETHEUS_COPY_CONFIG_PATH" "$PROMETHEUS_CONFIG_PATH"
}

setup_app_server() {
	local VAR1="JBOSS_MODULES_SYSTEM_PKGS=\"org\.jboss\.byteman\""
	local VAR2="JBOSS_MODULES_SYSTEM_PKGS=\"org.jboss.byteman,org.jboss.logmanager\""

	sed -i "s;$VAR1;$VAR2;" "$APPSERVER_BIN_PATH/standalone.conf"

	local BOOT_CLASSPATH1=`ls "$APPSERVER_HOME_PATH/modules/system/layers/base/org/jboss/logmanager/main/jboss-logmanager-"*".jar"`
	local BOOT_CLASSPATH2=`ls "$APPSERVER_HOME_PATH/modules/system/layers/base/org/wildfly/common/main/wildfly-common-"*".jar"`

	cat >> "$APPSERVER_BIN_PATH/standalone.conf" << EOF

JAVA_OPTS="\
-Xbootclasspath/p:'$BOOT_CLASSPATH1' \
-Xbootclasspath/p:'$BOOT_CLASSPATH2' \
-Djava.util.logging.manager=org.jboss.logmanager.LogManager \
-javaagent:'$PROMETHEUS_LIBRARY_PATH'=9779:'$PROMETHEUS_CONFIG_PATH' \
\$JAVA_OPTS"
EOF
}

if [ "x$PROMETHEUS_DOWNLOAD_URL" != "x" ] && [ "x$PROMETHEUS_COPY_CONFIG_PATH" != "x" ]
then
	echo "Setup Prometheus JMX exporter"

	download_files
	copy_files
	setup_app_server
fi
