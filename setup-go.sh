#!/bin/bash -eux
TEMP="$(mktemp -d)"
trap 'rm -rf $TEMP' EXIT ERR INT

ARCH=$(dpkg --print-architecture)
GO_LINUX_PACKAGE_URL="https://go.dev/dl/$(curl https://go.dev/VERSION?m=text | head -n1).linux-${ARCH}.tar.gz"
if [[ "${INPUT_GOVERSION##*/}" == "go.mod" ]]; then
    INPUT_GOVERSION=$(grep -e '^go' -m 1 ${INPUT_GOVERSION} | sed -e 's/go //g')
elif [[ "${INPUT_GOVERSION##*/}" == ".tool-versions" ]]; then
    INPUT_GOVERSION=$(grep -e '^go' -m 1 ${INPUT_GOVERSION} | sed -E 's/go(lang)? //g')
fi
if [[ ${INPUT_GOVERSION} =~ ^1\.[0-9]+$ ]]; then
    LATEST_MINOR_GOVERSION=$(curl -s https://go.dev/dl/ | grep -oP "go${INPUT_GOVERSION}\.\d+" | head -n 1 | cut -c 3-)
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go${LATEST_MINOR_GOVERSION}.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == http* ]]; then
    GO_LINUX_PACKAGE_URL=${INPUT_GOVERSION}
elif [[ -n ${INPUT_GOVERSION} ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go${INPUT_GOVERSION}.linux-${ARCH}.tar.gz"
fi

wget --progress=dot:mega ${GO_LINUX_PACKAGE_URL} -O "$TEMP/go-linux.tar.gz"
(
    cd "$TEMP" || exit 1
    tar -zxf go-linux.tar.gz
    mv go /usr/local/
)
mkdir -p /go/bin /go/src /go/pkg

export GO_HOME=/usr/local/go
export GOPATH=/go
export PATH=${GOPATH}/bin:${GO_HOME}/bin/:$PATH
