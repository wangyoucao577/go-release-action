#!/bin/sh

set -eux

# prepare binary/release name
BINARY_NAME=$(basename ${GITHUB_REPOSITORY})
if [ x${INPUT_BINARY_NAME} != x ]; then
  BINARY_NAME=${INPUT_BINARY_NAME}
fi
RELEASE_TAG=$(basename ${GITHUB_REF})
RELEASE_ASSET_NAME=${BINARY_NAME}-${RELEASE_TAG}-${INPUT_GOOS}-${INPUT_GOARCH}

# prepare upload URL
RELEASE_ASSETS_UPLOAD_URL=$(cat ${GITHUB_EVENT_PATH} | jq -r .release.upload_url)
RELEASE_ASSETS_UPLOAD_URL=${RELEASE_ASSETS_UPLOAD_URL/\{?name,label\}/}

# build binary
cd ${INPUT_PROJECT_PATH}
EXT=''
if [ ${INPUT_GOOS} == 'windows' ]; then
  EXT='.exe'
fi
go build -o "${BINARY_NAME}${EXT}"
ls -lh


# tar binary and calculate checksum
TAR_GZ_EXT='.tar.gz'
tar cvfz ${RELEASE_ASSET_NAME}${TAR_GZ_EXT} "${BINARY_NAME}${EXT}"
MD5_SUM=$(md5sum ${RELEASE_ASSET_NAME}${TAR_GZ_EXT} | cut -d ' ' -f 1)

# update binary and checksum
curl \
  --fail \
  -X POST \
  --data-binary @${RELEASE_ASSET_NAME}${TAR_GZ_EXT} \
  -H 'Content-Type: application/gzip' \
  -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
  "${RELEASE_ASSETS_UPLOAD_URL}?name=${RELEASE_ASSET_NAME}${TAR_GZ_EXT}"
echo $?

curl \
  --fail \
  -X POST \
  --data ${MD5_SUM} \
  -H 'Content-Type: text/plain' \
  -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
  "${RELEASE_ASSETS_UPLOAD_URL}?name=${RELEASE_ASSET_NAME}${TAR_GZ_EXT}.md5"
echo $?
