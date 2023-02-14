#!/bin/bash -eux

# prepare binary_name/release_tag/release_asset_name
BINARY_NAME=$(basename "$GITHUB_REPOSITORY")
if [[ $INPUT_BINARY_NAME ]]; then
    BINARY_NAME=$INPUT_BINARY_NAME
fi
RELEASE_TAG=$(basename "$GITHUB_REF")
if [[ $INPUT_RELEASE_TAG ]]; then
    RELEASE_TAG=${INPUT_RELEASE_TAG}
elif [[ $INPUT_RELEASE_NAME ]]; then
    # prevent upload-asset by tag due to github-ref default if a name is given
    RELEASE_TAG=""
fi

RELEASE_NAME=$INPUT_RELEASE_NAME

RELEASE_ASSET_NAME=${BINARY_NAME}-${RELEASE_TAG}-${INPUT_GOOS}-${INPUT_GOARCH}
if [[ $INPUT_GOAMD64 ]]; then
    RELEASE_ASSET_NAME=${BINARY_NAME}-${RELEASE_TAG}-${INPUT_GOOS}-${INPUT_GOARCH}-${INPUT_GOAMD64}
fi
if [[ $INPUT_ASSET_NAME ]]; then
    RELEASE_ASSET_NAME=${INPUT_ASSET_NAME}
fi

# prompt error if non-supported event
if [[ $GITHUB_EVENT_NAME == release ]]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
elif [[ $GITHUB_EVENT_NAME == push ]]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
elif [[ $GITHUB_EVENT_NAME == workflow_dispatch ]]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
elif [[ $GITHUB_EVENT_NAME == workflow_run ]]; then
    echo "Event: ${GITHUB_EVENT_NAME}"
else
    echo "Unsupport event: ${GITHUB_EVENT_NAME}!"
    exit 1
fi

# execute pre-command if exist, e.g. `go get -v ./...`
if [[ $INPUT_PRE_COMMAND ]]; then
    eval "$INPUT_PRE_COMMAND"
fi

# binary suffix
EXT=''
if [[ $INPUT_GOOS == windows ]]; then
    EXT='.exe'
fi

# prefix for ldflags
LDFLAGS_PREFIX=''
if [[ $INPUT_LDFLAGS ]]; then
    LDFLAGS_PREFIX="-ldflags"
fi

# fulfill GOAMD64 option
if [[ $INPUT_GOAMD64 ]]; then
    if [[ $INPUT_GOARCH =~ amd64 ]]; then
        GOAMD64_FLAG=$INPUT_GOAMD64
    else
        echo "GOAMD64 should only be use with amd64 arch." >&2
        GOAMD64_FLAG=""
    fi
else
    if [[ $INPUT_GOARCH =~ amd64 ]]; then
        GOAMD64_FLAG="v1"
    else
        GOAMD64_FLAG=""
    fi
fi

# build
BUILD_ARTIFACTS_FOLDER=build-artifacts-$(date +%s)
mkdir -p "${INPUT_PROJECT_PATH}/${BUILD_ARTIFACTS_FOLDER}"
cd "${INPUT_PROJECT_PATH}"
if [[ $INPUT_BUILD_COMMAND =~ ^make.* ]]; then
    # start with make, assumes using make to build golang binaries, execute it directly
    GOAMD64=$GOAMD64_FLAG \
        GOOS=$INPUT_GOOS \
        GOARCH=$INPUT_GOARCH \
        eval "$INPUT_BUILD_COMMAND"
    if [[ -f ${BINARY_NAME}${EXT} ]]; then
        # assumes the binary will be generated in current dir, copy it for later processes
        cp "${BINARY_NAME}${EXT}" "${BUILD_ARTIFACTS_FOLDER}/"
    fi
else
    GOAMD64=$GOAMD64_FLAG \
        GOOS=$INPUT_GOOS \
        GOARCH=$INPUT_GOARCH \
        eval "$INPUT_BUILD_COMMAND" \
        -o "${BUILD_ARTIFACTS_FOLDER}/${BINARY_NAME}${EXT}" \
        "$INPUT_BUILD_FLAGS" \
        "$LDFLAGS_PREFIX" "$INPUT_LDFLAGS"
fi


# executable compression
if [[ $INPUT_EXECUTABLE_COMPRESSION =~ ^upx.* ]]; then
    eval "$INPUT_EXECUTABLE_COMPRESSION" \
         "${BUILD_ARTIFACTS_FOLDER}/${BINARY_NAME}${EXT}"
elif [[ $INPUT_EXECUTABLE_COMPRESSION ]]; then
    echo "Unsupported executable compression: ${INPUT_EXECUTABLE_COMPRESSION}!" >&2
    exit 1
fi

# prepare extra files
if [[ $INPUT_EXTRA_FILES ]]; then
    cd "$GITHUB_WORKSPACE"
    # shellcheck disable=SC2086
    cp -r $INPUT_EXTRA_FILES "${INPUT_PROJECT_PATH}/${BUILD_ARTIFACTS_FOLDER}/"
    cd -
fi

if [[ ${INPUT_TARBOMB^^} == TRUE ]]; then
    cd "$BUILD_ARTIFACTS_FOLDER"
    SOURCE_DIR=.
    ls -lha
else
    ls -lha "$BUILD_ARTIFACTS_FOLDER"
    SOURCE_DIR=$BUILD_ARTIFACTS_FOLDER
fi

# INPUT_COMPRESS_ASSETS=='TRUE' is used for backwards compatability. `AUTO`,
# `ZIP`, `OFF` are the recommended values
if [[ ${INPUT_COMPRESS_ASSETS^^} =~ ^(TRUE|AUTO|ZIP)$ ]]; then
    # compress and package binary, then calculate checksum
    RELEASE_ASSET_EXT='.tar.gz'
    MEDIA_TYPE='application/gzip'
    RELEASE_ASSET_FILE=${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}
    if [[ $INPUT_GOOS == windows || ${INPUT_COMPRESS_ASSETS^^} == "ZIP" ]]; then
        RELEASE_ASSET_EXT='.zip'
        MEDIA_TYPE='application/zip'
        RELEASE_ASSET_FILE=${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}
        (
            shopt -s dotglob
            zip -vr "$RELEASE_ASSET_FILE" "$SOURCE_DIR/"*
        )
    else
        (
            shopt -s dotglob
            tar -czvf "$RELEASE_ASSET_FILE" "$SOURCE_DIR/"*
        )
    fi
elif [[ ${INPUT_COMPRESS_ASSETS} =~ ^(OFF|FALSE)$ ]]; then
    RELEASE_ASSET_EXT=$EXT
    MEDIA_TYPE="application/octet-stream"
    RELEASE_ASSET_FILE=${RELEASE_ASSET_NAME}${RELEASE_ASSET_EXT}
    cp "${BINARY_NAME}${EXT}" "$RELEASE_ASSET_FILE"
else
    echo "Invalid value for INPUT_COMPRESS_ASSETS: ${INPUT_COMPRESS_ASSETS} . Acceptable values are AUTO,ZIP, or OFF." >&2
    exit 1
fi
MD5_SUM=$(md5sum "$RELEASE_ASSET_FILE" | cut -d ' ' -f 1)
SHA256_SUM=$(sha256sum "$RELEASE_ASSET_FILE" | cut -d ' ' -f 1)

# prefix upload extra params
GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS=''
if [[ ${INPUT_OVERWRITE^^} == TRUE ]]; then
    GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS="-overwrite"
fi

# update binary and checksum
github-assets-uploader \
    -logtostderr \
    -f "$RELEASE_ASSET_FILE" \
    -mediatype "$MEDIA_TYPE" \
    $GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS \
    -repo "$GITHUB_REPOSITORY" \
    -token "$INPUT_GITHUB_TOKEN" \
    -tag="$RELEASE_TAG" \
    -releasename="$RELEASE_NAME" \
    -retry "$INPUT_RETRY"

if [[ ${INPUT_MD5SUM^^} == TRUE ]]; then
    MD5_EXT='.md5'
    MD5_MEDIA_TYPE='text/plain'
    echo "$MD5_SUM" > "${RELEASE_ASSET_FILE}${MD5_EXT}"
    github-assets-uploader \
        -logtostderr \
        -f "${RELEASE_ASSET_FILE}${MD5_EXT}" \
        -mediatype "$MD5_MEDIA_TYPE" \
        $GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS \
        -repo "$GITHUB_REPOSITORY" \
        -token "$INPUT_GITHUB_TOKEN" \
        -tag="$RELEASE_TAG" \
        -releasename="$RELEASE_NAME" \
        -retry "$INPUT_RETRY"
fi

if [[ ${INPUT_SHA256SUM^^} == TRUE ]]; then
    SHA256_EXT='.sha256'
    SHA256_MEDIA_TYPE='text/plain'
    echo "$SHA256_SUM" > "${RELEASE_ASSET_FILE}${SHA256_EXT}"
    github-assets-uploader \
        -logtostderr \
        -f "${RELEASE_ASSET_FILE}${SHA256_EXT}" \
        -mediatype "$SHA256_MEDIA_TYPE" \
        $GITHUB_ASSETS_UPLOADR_EXTRA_OPTIONS \
        -repo "$GITHUB_REPOSITORY" \
        -token "$INPUT_GITHUB_TOKEN" \
        -tag="$RELEASE_TAG" \
        -releasename="$RELEASE_NAME" \
        -retry "$INPUT_RETRY"
fi

# execute post-command if exist, e.g. upload to AWS s3 or aliyun OSS
if [[ $INPUT_POST_COMMAND ]]; then
    eval "${INPUT_POST_COMMAND}"
fi
