#!/bin/sh

export SCRIPT_DIR="$( cd "$( dirname "$0" )" > /dev/null && pwd )"

sh "$SCRIPT_DIR/build.sh"

sh "$SCRIPT_DIR/setup.sh"
