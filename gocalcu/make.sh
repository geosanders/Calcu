#!/bin/bash

pushd . > /dev/null
ABSPATH=$(cd "$(dirname "$0")"; pwd)
popd > /dev/null

export GOPATH=$ABSPATH

echo "GOPATH is set to: $GOPATH"

echo "Getting dependencies..."

# get dependencies if not done already
go get code.google.com/p/go.net/websocket
go get github.com/jessevdk/go-flags
go get github.com/tarm/goserial

echo "Building..."

# build
go install gocalcu

