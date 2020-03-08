#!/bin/bash -eux

# prepare golang
source /setup-go.sh 
go version

# build & release go binaries
/release.sh

