#!/bin/bash -eux
TEMP="$(mktemp -d)"
trap 'rm -rf $TEMP' EXIT ERR INT

ARCH=$(dpkg --print-architecture)
GO_LINUX_PACKAGE_URL="https://go.dev/dl/$(curl https://go.dev/VERSION?m=text | head -n1).linux-${ARCH}.tar.gz"
if [[ "${INPUT_GOVERSION##*/}" == "go.mod" ]]; then
    INPUT_GOVERSION=$(grep -e '^go' -m 1 ${INPUT_GOVERSION} | sed -e 's/go //g')
fi
if [[ ${INPUT_GOVERSION} == "1.19" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.19.1.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == "1.18" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.18.6.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == "1.17" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.17.13.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == "1.16" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.16.15.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == "1.15" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.15.15.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == "1.14" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.14.15.linux-${ARCH}.tar.gz"
elif [[ ${INPUT_GOVERSION} == "1.13" ]]; then
    GO_LINUX_PACKAGE_URL="https://go.dev/dl/go1.13.15.linux-${ARCH}.tar.gz"
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
