#!/bin/sh

source "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	append_to_cli "/subsystem=elytron/key-store=server_key_store:add(path=\"$JKS_FILE_PATH\", credential-reference={clear-text=\"$JKS_STORE_PASSWORD\"}, type=JKS)"
	append_to_cli "/subsystem=elytron/key-manager=server_key_manager:add(key-store=server_key_store, credential-reference={clear-text=\"$JKS_KEY_PASSWORD\"})"
	append_to_cli "/subsystem=elytron/server-ssl-context=server_key_ssl_context:add(key-manager=server_key_manager, protocols=[TLSv1.2])"

	append_to_cli "/subsystem=undertow/server=default-server/https-listener=https:undefine-attribute(name=security-realm)"
	append_to_cli "/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=ssl-context, value=server_key_ssl_context)"
}

if [ "x$JKS_FILE_PATH" != "x" ] && [ "x$JKS_STORE_PASSWORD" != "x" ] && [ "x$JKS_KEY_PASSWORD" != "x" ]
then
	echo "Setup JKS"

	setup_app_server
fi
