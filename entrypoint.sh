#!/bin/bash -eux

# prepare golang
# shellcheck source=./setup-go.sh
source /setup-go.sh 

# easy to debug if anything wrong
go version
env

# build & release go binaries
/release.sh

