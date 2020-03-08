#!/bin/sh -eux

wget --progress=dot:mega https://dl.google.com/go/go1.14.linux-amd64.tar.gz -O go-linux-amd64.tar.gz 
tar -zxf go-linux-amd64.tar.gz
mv go /usr/local/
mkdir -p /go/bin /go/src /go/pkg

export GO_HOME=/usr/local/go
export PATH=${GO_HOME}/bin/:$PATH
export GOPATH=/go


