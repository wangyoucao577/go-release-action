#!/bin/bash -eux

# prepare binary_name/release_tag/release_asset_name
BINARY_NAME=$(basename ${GITHUB_REPOSITORY})
if [ x${INPUT_BINARY_NAME} != x ]; then
  BINARY_NAME=${INPUT_BINARY_NAME}
fi
RELEASE_TAG=$(basename ${GITHUB_REF})
if [ ! -z "${INPUT_RELEASE_TAG}" ]; then
    RELEASE_TAG=${INPUT_RELEASE_TAG}
fi
RELEASE_ASSET_NAME=${BINARY_NAME}-${RELEASE_TAG}-${INPUT_GOOS}-${INPUT_GOARCH}
if [ ! -z "${INPUT_ASSET_NAME}" ]; then
    RELEASE_ASSET_NAME=${INPUT_ASSET_NAME}
fi

# prompt error if non-supported event
if [ ${GITHUB_EVENT_NAME} == 'release' ]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
elif [ ${GITHUB_EVENT_NAME} == 'push' ]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
elif [ ${GITHUB_EVENT_NAME} == 'workflow_dispatch' ]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
else
    echo "Unsupport event: ${GITHUB_EVENT_NAME}!"
    exit 1
fi

# execute pre-command if exist, e.g. `go get -v ./...`
if [ ! -z "${INPUT_PRE_COMMAND}" ]; then
    eval ${INPUT_PRE_COMMAND}
fi

# binary suffix
EXT=''
if [ ${INPUT_GOOS} == 'windows' ]; then
  EXT='.exe'
fi

# prefix for ldflags 
LDFLAGS_PREFIX=''
if [ ! -z "${INPUT_LDFLAGS}" ]; then
    LDFLAGS_PREFIX="-ldflags"
fi

# build
BUILD_ARTIFACTS_FOLDER=build-artifacts-$(date +%s)
mkdir -p ${INPUT_PROJECT_PATH}/${BUILD_ARTIFACTS_FOLDER}
cd ${INPUT_PROJECT_PATH}
if [[ "${INPUT_BUILD_COMMAND}" =~ ^make.* ]]; then
    # start with make, assumes using make to build golang binaries, execute it directly
    GOOS=${INPUT_GOOS} GOARCH=${INPUT_GOARCH} eval ${INPUT_BUILD_COMMAND}
    if [ -f "${BINARY_NAME}${EXT}" ]; then
        # assumes the binary will be generated in current dir, copy it for later processes
        cp ${BINARY_NAME}${EXT} ${BUILD_ARTIFACTS_FOLDER}/
    fi
else
    GOOS=${INPUT_GOOS} GOARCH=${INPUT_GOARCH} ${INPUT_BUILD_COMMAND} -o ${BUILD_ARTIFACTS_FOLDER}/${BINARY_NAME}${EXT} ${INPUT_BUILD_FLAGS} ${LDFLAGS_PREFIX} "${INPUT_LDFLAGS}" 
fi


# executable compression
if [ ! -z "${INPUT_EXECUTABLE_COMPRESSION}" ]; then
if [[ "${INPUT_EXECUTABLE_COMPRESSION}" =~ ^upx.* ]]; then
    # start with upx, use upx to compress the executable binary
    eval ${INPUT_EXECUTABLE_COMPRESSION} ${BUILD_ARTIFACTS_FOLDER}/${BINARY_NAME}${EXT}
else
    echo "Unsupport executable compression: ${INPUT_EXECUTABLE_COMPRESSION}!"
    exit 1
fi
fi

# prepare extra files
if [ ! -z "${INPUT_EXTRA_FILES}" ]; then
  cd ${GITHUB_WORKSPACE}
  cp -r ${INPUT_EXTRA_FILES} ${INPUT_PROJECT_PATH}/${BUILD_ARTIFACTS_FOLDER}/
  cd ${INPUT_PROJECT_PATH}
fi

cd ${BUILD_ARTIFACTS_FOLDER}
ls -lha

# compress and package binary, then calculate checksum
RELEASE_ASSET_EXT='.tar.gz'
MEDIA_TYPE='application/gzip'
if [ ${INPUT_GOOS} == 'windows' ]; then
RELEASE_ASSET_EXT='.zip'
MEDIA_TYPE='application/zip'
( shopt -s dotglob; zip -vr ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT} * )
else
( shopt -s dotglob; tar cvfz ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT} * )
fi
MD5_SUM=$(md5sum ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT} | cut -d ' ' -f 1)
SHA256_SUM=$(sha256sum ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT} | cut -d ' ' -f 1)

# prefix upload extra params 
GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS=''
if [ ${INPUT_OVERWRITE^^} == 'TRUE' ]; then
    GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS="-overwrite"
fi

# update binary and checksum
github-assets-uploader -logtostderr -f ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT} -mediatype ${MEDIA_TYPE} ${GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS} -repo ${GITHUB_REPOSITORY} -token ${INPUT_GITHUB_TOKEN} -tag ${RELEASE_TAG} -retry ${INPUT_RETRY}
if [ ${INPUT_MD5SUM^^} == 'TRUE' ]; then
MD5_EXT='.md5'
MD5_MEDIA_TYPE='text/plain'
echo ${MD5_SUM} >${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}${MD5_EXT}
github-assets-uploader -logtostderr -f ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}${MD5_EXT} -mediatype ${MD5_MEDIA_TYPE} ${GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS} -repo ${GITHUB_REPOSITORY} -token ${INPUT_GITHUB_TOKEN} -tag ${RELEASE_TAG} -retry ${INPUT_RETRY}
fi

if [ ${INPUT_SHA256SUM^^} == 'TRUE' ]; then
SHA256_EXT='.sha256'
SHA256_MEDIA_TYPE='text/plain'
echo ${SHA256_SUM} >${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}${SHA256_EXT}
github-assets-uploader -logtostderr -f ${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}${SHA256_EXT} -mediatype ${SHA256_MEDIA_TYPE} ${GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS} -repo ${GITHUB_REPOSITORY} -token ${INPUT_GITHUB_TOKEN} -tag ${RELEASE_TAG} -retry ${INPUT_RETRY}
fi
