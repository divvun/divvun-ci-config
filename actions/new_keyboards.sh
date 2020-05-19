#!/bin/bash
set -ex

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REGEX=$1

# Get all the repos and add CI
gut clone -o giellalt -r $REGEX
gut checkout -o giellalt -r $REGEX -b develop
gut ci export -t $SCRIPTPATH/keyboard -o giellalt -r $REGEX --output /tmp/x.toml --script $SCRIPTPATH/autoconf_json.sh
gut ci generate -t $SCRIPTPATH/keyboard -o giellalt -r $REGEX -d /tmp/x.toml
rm /tmp/x.toml
gut commit -o giellalt -r $REGEX -m "Add initial CI configuration"

# Get all the repos and add them to the pahkat repo properly
export PAHKAT_REPO=$2
gut apply -o giellalt -r $REGEX -s "$SCRIPTPATH/init_pahkat_pkg_keyboard.sh"