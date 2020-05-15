#!/bin/bash
set -e

# REQUIRES ENV VAR: PAHKAT_REPO
# run by gut apply in a repo
echo "AHHH"

ID=`grep "^name =" .gut/manifest.toml | cut -d' '  -f3 | cut -d'"' -f2`
NAME_EN=`grep "^human_name =" .gut/manifest.toml | cut -d'"'  -f2`
TAG=`grep "^filename =" .gut/manifest.toml | cut -d' '  -f3 | cut -d'"' -f2 | cut -d'-' -f1`

repomgr package init "speller-${ID}" -d "" -n "${NAME_EN} Speller" -r $PAHKAT_REPO -t "lang:${TAG}" "cat:speller"
repomgr package init "speller-${ID}-mso" -d "" -n "${NAME_EN} MS Office Speller" -r $PAHKAT_REPO -t "lang:${TAG}" "cat:speller"