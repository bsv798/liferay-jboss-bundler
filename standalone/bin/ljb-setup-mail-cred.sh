#!/bin/sh

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	append_to_cli "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=liferay_mail_smtp:add(host=\"$MAIL_HOST\", port=$MAIL_PORT)"
	append_to_cli "/subsystem=mail/mail-session=liferay_mail:add(jndi-name=\"$MAIL_JNDI_NAME\")"

	if [ "x$MAIL_USERNAME" != "x" ] && [ "x$MAIL_PASSWORD" != "x" ]
	then
		append_to_cli "/subsystem=elytron/credential-store=mail_credential_store:add-alias(alias=liferay_mail, secret-value=\"$MAIL_PASSWORD\")"
		append_to_cli "/subsystem=mail/mail-session=liferay_mail/server=smtp:add(outbound-socket-binding-ref=liferay_mail_smtp, username=\"$MAIL_USERNAME\", credential-reference={store=mail_credential_store, alias=liferay_mail}, ssl=$MAIL_ENABLE_SSL, tls=$MAIL_ENABLE_TLS)"
	else
		append_to_cli "/subsystem=mail/mail-session=liferay_mail/server=smtp:add(outbound-socket-binding-ref=liferay_mail_smtp)"
	fi
}

setup_portal_properties() {
	echo "mail.session.jndi.name=$MAIL_JNDI_NAME" >> "$LIFERAY_HOME/portal-ext-bundle.properties"
}

if [ "x$MAIL_HOST" != "x" ] && [ "x$MAIL_PORT" != "x" ]
then
	echo "Setup Mail credentials"

	setup_app_server
	setup_portal_properties
fi
