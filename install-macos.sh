#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

bash $DIR/decrypt.sh || exit 1
bash $DIR/enc/install-macos.sh || exit 1
