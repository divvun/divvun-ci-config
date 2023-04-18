#! /bin/bash
# This script downloads and extracts a zhfst file
#
# Requires: wget, ar, tar

set -eo pipefail

if [ -z "$1" ]; then
  echo "First argument needs to be the download url"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Second argument needs to be the path to zhfst file"
  exit 1
fi

if [ -z "$3" ]; then
  echo "Third argument needs to be the output file name"
  exit 1
fi

URL="$1"
FILE_PATH="$2"
OUTPUT_FILE="$3"
OPTION="$4"

set -u

TMP_FOLDER="./tmp-download"
OUTPUT_DIR=$(pwd)

mkdir -p "$TMP_FOLDER" > /dev/null
pushd "$TMP_FOLDER" > /dev/null
echo "Downloading $URL"
wget -q -r -nd -np -A deb -e robots=off "$URL"
popd > /dev/null

for f in "$TMP_FOLDER"/*.deb; do
  echo "Extracting $f"
  mkdir -p tmp > /dev/null
  cd tmp
  ar x "../$f"
  if [ -f data.tar.gz ]; then
    tar xf data.tar.gz
  elif [ -f data.tar.xz ]; then
    tar xf data.tar.xz
  else 
   echo "Invalid file: $URL"
   exit 1;
  fi

  if [ -f "$FILE_PATH" ]; then
    mv "$FILE_PATH" "$OUTPUT_DIR/$3"
  fi
  cd ..
  rm -r tmp
done

rm -r "$TMP_FOLDER"

if [ "$OPTION" == "--bhfst" ]; then
    if [ -f "$OUTPUT_DIR/$OUTPUT_FILE" ]; then
      echo "Downloading thfst-tools"
      if [[ "$OSTYPE" == "linux-gnu" ]]; then
        wget -O thfst-tools -q https://github.com/divvun/divvunspell/releases/download/v1.0.0-alpha.2/thfst-tools_linux
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        wget -O thfst-tools -q https://github.com/divvun/divvunspell/releases/download/v1.0.0-alpha.2/thfst-tools_macos
      else
        echo "Unknown OS: $OSTYPE"
      fi
      chmod +x ./thfst-tools
      echo "Converting zhfst to bhfst"
      ./thfst-tools zhfst-to-bhfst "$OUTPUT_DIR/$OUTPUT_FILE" > /dev/null
    fi
fi

if [ -f "$OUTPUT_DIR/$OUTPUT_FILE" ]; then
    echo "Successfully downloaded $OUTPUT_DIR/$OUTPUT_FILE"
fi

exit 0
