#!/bin/sh

source "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

setup_app_server() {
	local DEP_PATH=`echo "$LIFERAY_HOME/dependencies" | sed "s/\ /\\\\\ /g"`
	local FILES=`ls "$LIFERAY_HOME/dependencies"`
	local FILE_STRING=

	for FILE in $FILES
	do
		FILE_STRING=$DEP_PATH/$FILE,$FILE_STRING
	done

	if [ "x$FILE_STRING" != "x" ]
	then
		FILE_STRING="${FILE_STRING%?}"

		append_to_cli "module add --name=com.liferay.portal --resource-delimiter=, --resources=$FILE_STRING --dependencies=javax.api,javax.mail.api,javax.servlet.api,javax.servlet.jsp.api,javax.transaction.api,javax.xml.bind.api"

		execute_cli
	fi
}

clean_temporary_resources() {
	rm -rf "$LIFERAY_HOME/dependencies" 2> /dev/null
	rm "$APPSERVER_SETUP_CLI_PATH" 2> /dev/null
}

setup_app_server

echo "Clean temporary resources"

clean_temporary_resources
