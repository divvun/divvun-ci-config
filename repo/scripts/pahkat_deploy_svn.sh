# This script deploys a CI artifact to a svn repository
# used by Pahkat. It will add the file and update the package
# JSON to use the new file.
#
# Requires: svn, pahkat
#
# Required environmental variables:
#   DEPLOY_SVN_COMMIT    Set 1 to actually commit to svn
#   DEPLOY_SVN_USER      The svn credentials username
#   DEPLOY_SVN_PASSWORD  The svn credentials password

set -e

if [ -z "$1" ]; then
  echo "First argument needs to be the svn url"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Second argument needs to be the full artifact file path"
  exit 1
fi

if [ ! -f "$2" ]; then
    echo "Deploy artifact not found at: $2"
    exit 1
fi

if [ -z "$3" ]; then
  echo "Third argument needs to be the pahkat package id"
  exit 1
fi

if [ -z "$4" ]; then
  echo "Fourth argument needs to be the pahkat package version"
  exit 1
fi

INTERMEDIATE_REPO="intermediate-svn"
RETRIES=0
MAX_RETRIES=5

while [ $RETRIES -le $MAX_RETRIES ]
do
  rm -rf $INTERMEDIATE_REPO
  svn checkout --depth immediates $1 $INTERMEDIATE_REPO
  cd $INTERMEDIATE_REPO
  svn up packages --set-depth=infinity
  svn up virtuals --set-depth=infinity
  svn up index.nightly.json

  DEPLOY_EXTENSION=${2##*.}
  DEPLOY_AS="$3-$(date -u +%Y%m%dT%H%M%SZ).$DEPLOY_EXTENSION"

  cp "$2" "./artifacts/$DEPLOY_AS"
  svn add "./artifacts/$DEPLOY_AS"

  # update the pahkat package description
  DEPLOY_FILE_SIZE=$(stat -f %z -- "$2")

  # mangle the pahkat json
  # NOTE: this is a rather bad method of doing this (for instance we assume that the
  #       lines we mangle end with , which might not be the case). however, we will
  #       probably move this to pahkat in the end
  cat "packages/$3/index.nightly.json" | \
    sed 's#"version".*#"version": "'$4'",#g' | \
    sed 's#"url".*#"url": "'$1'/artifacts/'$DEPLOY_AS'",#g' | \
    sed 's#"size".*#"size": '$DEPLOY_FILE_SIZE',#g' > "packages/$3/index.nightly.json.tmp"
  mv "packages/$3/index.nightly.json.tmp" "packages/$3/index.nightly.json"

  # re-index using pahkat
  pahkat repo index

  # run svn status to get the changes logged
  # then optionally commit changes
  svn status
  if [ "$DEPLOY_SVN_COMMIT" == "1" ]; then
      set +e
      svn commit -m "Automated Deploy: $3" --username=$DEPLOY_SVN_USER --password=$DEPLOY_SVN_PASSWORD
      if [[ $? -eq 0 ]]; then
        echo "Successfully deployed $2 to $1"
        exit 0
      fi
      set -e
      if [[ $RETRIES -lt $MAX_RETRIES ]]; then
        SLEEP_TIME=$(($RANDOM % 60))
        echo "Retrying in $SLEEP_TIME second(s).."
        sleep $SLEEP_TIME
      fi
      RETRIES=$((RETRIES+1))
  else
      echo "Warning: DEPLOY_SVN_COMMIT not set, ie. changes to repo will not be commited"
      exit 0
  fi
done

echo "Max retries reached while deploying $2 to $1"
exit 1
