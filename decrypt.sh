#!/usr/bin/env bash

if [[ -z "$DIVVUN_KEY" ]]; then
  echo "No DIVVUN_KEY set; aborting."
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

openssl aes-256-cbc -d -in $DIR/config.txz.enc -pass pass:"$DIVVUN_KEY" -md md5 | tar xfJ - -C $DIR