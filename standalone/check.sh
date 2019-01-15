#!/bin/sh

export SCRIPT_DIR="$( cd "$( dirname "$0" )" > /dev/null && pwd )"

. "$SCRIPT_DIR/bin/ljb-setup-conf.sh"

if [ "x$JKS_FILE_PATH" != "x" ] && [ "x$JKS_STORE_PASSWORD" != "x" ] && [ "x$JKS_KEY_PASSWORD" != "x" ]
then
	curl -f -s -k -o /dev/null https://127.0.0.1:8443/ || exit 1
else
	curl -f -s -o /dev/null http://127.0.0.1:8080/ || exit 1
fi
