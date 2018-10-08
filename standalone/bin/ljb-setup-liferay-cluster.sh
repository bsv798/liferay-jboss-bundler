#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_portal_properties() {
	cat > "$LIFERAY_HOME/osgi/configs/com.liferay.portal.bundle.blacklist.internal.BundleBlacklistConfiguration.config" << EOF
blacklistBundleSymbolicNames=["com.liferay.portal.cache.single","com.liferay.portal.cluster.single","com.liferay.portal.scheduler.single"]
EOF
	echo "cluster.link.enabled=true" >> "$LIFERAY_HOME/portal-ext-bundle.properties"
}

copy_files() {
	mkdir -p "$LIFERAY_HOME/osgi/portal"
	cp "$LIFERAY_COPY_CLUSTER_PATH"/* "$LIFERAY_HOME/osgi/portal"
}

if [ "x$LIFERAY_COPY_CLUSTER_PATH" != "x" ]
then
	echo "Setup Liferay clustering"

	setup_portal_properties
	copy_files
fi
