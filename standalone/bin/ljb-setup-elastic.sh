#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_portal_properties() {
	cat > "$LIFERAY_HOME/osgi/configs/com.liferay.portal.search.elasticsearch6.configuration.ElasticsearchConfiguration.config" << EOF
operationMode="REMOTE"
transportAddresses="$ELASTIC_TRANSPORT_ADDRESSES"
clusterName="$ELASTIC_CLUSTER_NAME"
logExceptionsOnly="true"
EOF
}

if [ "x$ELASTIC_TRANSPORT_ADDRESSES" != "x" ] && [ "x$ELASTIC_CLUSTER_NAME" != "x" ]
then
	echo "Setup Elasticsearch"

	setup_portal_properties
fi
