#!/bin/bash
set -e

# REQUIRES ENV VAR: PAHKAT_REPO
# run by gut apply in a repo
echo "AHHH"

ID=`grep "^name =" .gut/manifest.toml | cut -d' '  -f3 | cut -d'"' -f2`
NAME_EN=`yq read "$PWD/$ID.kbdgen/targets/mac.yaml" bundleName`

repomgr package init "keyboard-${ID}" -d "" -n "${NAME_EN}" -r $PAHKAT_REPO -t "lang:${ID}" "cat:keyboard-layouts"