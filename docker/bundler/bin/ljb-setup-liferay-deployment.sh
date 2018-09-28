#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

copy_files() {
	mkdir -p "$LIFERAY_DEPLOYMENT_PATH"
	cp "$LIFERAY_COPY_DEPLOYMENT_PATH"/* "$LIFERAY_DEPLOYMENT_PATH"
}

if [ "x$LIFERAY_COPY_DEPLOYMENT_PATH" != "x" ]
then
	echo "Setup Liferay deployments"

	copy_files
fi
