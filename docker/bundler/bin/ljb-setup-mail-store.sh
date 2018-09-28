#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	append_to_cli "/subsystem=elytron/credential-store=mail_credential_store:add(location=\"$APPSERVER_BIN_PATH/credential_store/mail_credential_store.jceks\", credential-reference={clear-text=\"$MAIL_CREDENTIAL_STORE_PASSWORD\"}, create=true)"
}

if [ "x$MAIL_CREDENTIAL_STORE_PASSWORD" != "x" ]
then
	echo "Setup Mail credential store"

	setup_app_server
fi
