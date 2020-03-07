#!/bin/sh

set -eux

# prepare binary name
BINARY_NAME=$(basename ${GITHUB_REPOSITORY})
if [ x${INPUT_BINARY_NAME} != x ]; then
  BINARY_NAME=${INPUT_BINARY_NAME}
fi

# prepare URL and name to upload assets
GITHUB_EVENT_DATA=$(cat ${GITHUB_EVENT_PATH})
echo ${GITHUB_EVENT_DATA} | jq .
RELEASE_ASSETS_UPLOAD_URL=$(echo ${GITHUB_EVENT_DATA} | jq -r .release.upload_url)
echo ${RELEASE_ASSETS_UPLOAD_URL}
RELEASE_ASSETS_UPLOAD_URL=${RELEASE_ASSETS_UPLOAD_URL/\{?name,label\}/}
echo ${RELEASE_ASSETS_UPLOAD_URL}
RELEASE_TAG=$(echo $GITHUB_EVENT_DATA | jq -r .release.tag_name)
echo ${RELEASE_TAG}
RELEASE_ASSET_NAME=${BINARY_NAME}_${RELEASE_TAG}_${GOOS}_${GOARCH}
echo ${RELEASE_ASSET_NAME}

# build binary
cd ${INPUT_PROJECT_PATH}
go build -o "${BINARY_NAME}"


# tar binary and calculate checksum
EXT=''
if [ $GOOS == 'windows' ]; then
  EXT='.exe'
fi
tar cvfz tmp.tar.gz "${BINARY_NAME}${EXT}"
CHECKSUM=$(md5sum tmp.tar.gz | cut -d ' ' -f 1)

# update binary and checksum
curl \
  -X POST \
  --data-binary @tmp.tar.gz \
  -H 'Content-Type: application/gzip' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${RELEASE_ASSETS_UPLOAD_URL}?name=${RELEASE_ASSET_NAME}.tar.gz"

curl \
  -X POST \
  --data $CHECKSUM \
  -H 'Content-Type: text/plain' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${RELEASE_ASSETS_UPLOAD_URL}?name=${RELEASE_ASSET_NAME}_checksum.txt"
