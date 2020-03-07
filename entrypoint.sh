#!/bin/sh

set -eux

# prepare binary/release name
BINARY_NAME=$(basename ${GITHUB_REPOSITORY})
if [ x${INPUT_BINARY_NAME} != x ]; then
  BINARY_NAME=${INPUT_BINARY_NAME}
fi
RELEASE_TAG=$(basename ${GITHUB_REF})
RELEASE_ASSET_NAME=${BINARY_NAME}-${RELEASE_TAG}-${GOOS}-${GOARCH}

# prepare upload URL
RELEASE_ASSETS_UPLOAD_URL=$(cat ${GITHUB_EVENT_PATH} | jq -r .release.upload_url)
RELEASE_ASSETS_UPLOAD_URL=${RELEASE_ASSETS_UPLOAD_URL/\{?name,label\}/}

# build binary
cd ${INPUT_PROJECT_PATH}
EXT=''
if [ $GOOS == 'windows' ]; then
  EXT='.exe'
fi
go build -o "${BINARY_NAME}${EXT}"


# tar binary and calculate checksum
tar cvfz tmp.tar.gz "${BINARY_NAME}${EXT}"
CHECKSUM=$(md5sum tmp.tar.gz | cut -d ' ' -f 1)

# update binary and checksum
curl \
  -X POST \
  --data-binary @tmp.tar.gz \
  -H 'Content-Type: application/gzip' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${RELEASE_ASSETS_UPLOAD_URL}?name=${RELEASE_ASSET_NAME}.tar.gz"
echo $?

curl \
  -X POST \
  --data ${CHECKSUM} \
  -H 'Content-Type: text/plain' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${RELEASE_ASSETS_UPLOAD_URL}?name=${RELEASE_ASSET_NAME}_checksum.txt"
echo $?
