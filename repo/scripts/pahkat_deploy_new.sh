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

# DEPLOY_SVN_REPO
# DEPLOY_SVN_PKG_ID
# DEPLOY_SVN_PKG_PLATFORM
# DEPLOY_SVN_PKG_PAYLOAD
# DEPLOY_SVN_PKG_VERSION

if [ -z "$DEPLOY_SVN_REPO" ]; then
  echo "DEPLOY_SVN_REPO missing"
  exit 1
fi

if [ -z "$DEPLOY_SVN_PKG_ID" ]; then
  echo "DEPLOY_SVN_PKG_ID missing"
  exit 1
fi

if [ -z "$DEPLOY_SVN_PKG_PAYLOAD" ]; then
  echo "DEPLOY_SVN_PKG_PAYLOAD missing"
  exit 1
fi

if [ ! -f "$DEPLOY_SVN_PKG_PAYLOAD" ]; then
    echo "Deploy artifact not found at: $DEPLOY_SVN_PKG_PAYLOAD"
    exit 1
fi

if [ -n "$DEPLOY_SVN_PKG_PAYLOAD_METADATA" ]; then
  PAYLOAD_METADATA_FLAG="--payload-path $DEPLOY_SVN_PKG_PAYLOAD_METADATA"
else
  PAYLOAD_METADATA_FLAG=""
fi

if [ -z "$DEPLOY_SVN_PKG_VERSION" ]; then
  echo "DEPLOY_SVN_PKG_VERSION missing"
  exit 1
fi

if [ -z "$DEPLOY_SVN_PKG_PLATFORM" ]; then
  echo "DEPLOY_SVN_PKG_PLATFORM missing"
  exit 1
fi

if [ -z "$DEPLOY_SVN_REPO_ARTIFACTS" ]; then
  echo "DEPLOY_SVN_REPO_ARTIFACTS missing"
  exit 1
fi

#https://pahkat.uit.no/

INTERMEDIATE_REPO="intermediate-svn"
RETRIES=0
MAX_RETRIES=5

PAYLOAD_URL=""


while [ $RETRIES -le $MAX_RETRIES ]
do
  rm -rf "$INTERMEDIATE_REPO"
  svn checkout --depth empty $DEPLOY_SVN_REPO_ARTIFACTS $INTERMEDIATE_REPO
  cd $INTERMEDIATE_REPO

  # VERSION=$(date -u +%Y%m%dT%H%M%SZ)
  DEPLOY_EXTENSION=${DEPLOY_SVN_PKG_PAYLOAD##*.}
  DEPLOY_AS="$DEPLOY_SVN_PKG_ID-$DEPLOY_SVN_PKG_VERSION.$DEPLOY_EXTENSION"
  echo "[!] Attempting to deploy $DEPLOY_AS"

  cp "$DEPLOY_SVN_PKG_PAYLOAD" "./$DEPLOY_AS"
  svn add "./$DEPLOY_AS"

  PAYLOAD_URL="${DEPLOY_SVN_REPO_ARTIFACTS%/}/$DEPLOY_AS"
  echo $PAYLOAD_URL

  svn status
  if [ "$DEPLOY_SVN_COMMIT" == "1" ]; then
      set +e
      echo "[!] Committing $PAYLOAD_URL"

      svn commit -m "Automated Deploy: $DEPLOY_SVN_PKG_ID" --username=$DEPLOY_SVN_USER --password=$DEPLOY_SVN_PASSWORD
      if [[ $? -eq 0 ]]; then
        echo "Successfully deployed $DEPLOY_SVN_PKG_ID to $DEPLOY_SVN_REPO"
        break
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
      break
  fi
done

echo $DEPLOY_SVN_PKG_VERSION
echo $PAYLOAD_URL

if [ -z "$PAYLOAD_URL" ]; then
  echo "Max retries reached while deploying artifact of $DEPLOY_SVN_PKG_ID to $DEPLOY_SVN_REPO_ARTIFACTS"
  exit 1
fi

while [ $RETRIES -le $MAX_RETRIES ]
do
  echo "[!] Updating repository index"
  rm -rf "$INTERMEDIATE_REPO"
  svn checkout --depth immediates $DEPLOY_SVN_REPO $INTERMEDIATE_REPO
  cd $INTERMEDIATE_REPO
  svn up packages --set-depth=infinity
  svn up string --set-depth=infinity
  svn up index.toml

  echo "[!] Adding $DEPLOY_SVN_PKG_ID $DEPLOY_SVN_PKG_VERSION for platform $DEPLOY_SVN_PKG_PLATFORM on channel 'nightly'"
  echo "    URL: $PAYLOAD_URL"
  pahkat-repomgr package update "$DEPLOY_SVN_PKG_ID" -r . -c nightly -p "$DEPLOY_SVN_PKG_PLATFORM" -u "$PAYLOAD_URL" -v "$DEPLOY_SVN_PKG_VERSION" $PAYLOAD_METADATA_FLAG
  if [[ $? -ne 0 ]]; then
    echo "Updating index.toml failed"
    exit 1
  fi

  pahkat-repomgr repo index
  if [[ $? -ne 0 ]]; then
    echo "Updating index.bin failed"
    exit 1
  fi

  # run svn status to get the changes logged
  # then optionally commit changes
  svn status
  if [ "$DEPLOY_SVN_COMMIT" == "1" ]; then
      set +e
      echo "[!] Committing repository index update"
      svn commit -m "Automated Deploy: $DEPLOY_SVN_PKG_ID" --username=$DEPLOY_SVN_USER --password=$DEPLOY_SVN_PASSWORD
      if [[ $? -eq 0 ]]; then
        echo "Successfully deployed $DEPLOY_SVN_PKG_ID to $DEPLOY_SVN_REPO"
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

echo "Max retries reached while deploying $DEPLOY_SVN_PKG_ID to $DEPLOY_SVN_REPO"
exit 1
