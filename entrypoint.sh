#!/bin/bash -eux

# prepare golang
# shellcheck disable=SC1091
source /setup-go.sh

# easy to debug if anything wrong
go version
env

# build & release go binaries
/release.sh
