#!/bin/sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$SCRIPT_DIR/ljb-setup-conf.sh"

setup_app_server() {
	local DEP_PATH=`echo "$LIFERAY_HOME/dependencies" | sed "s/\ /\\\\\ /g"`
	local FILE_LIST=(`ls -p "$LIFERAY_HOME/dependencies" 2> /dev/null | grep -v / | tr '\n' ' '`)
	local FILE_LEN=${#FILE_LIST[@]}
	local FILE_STRING=$DEP_PATH/${FILE_LIST[0]}

	for (( i = 1; i < $FILE_LEN; i++ )); do
	    local FILE=${FILE_LIST[$i]}

	    FILE_STRING=$FILE_STRING,$DEP_PATH/$FILE
	done

	if [ "$FILE_LEN" -gt "0" ]
	then
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
