@echo off

echo NOTE: go version 1.1+ required

set GOPATH=%~dp0

echo GOPATH is set to: %GOPATH%

echo Getting dependencies...

rem get dependencies if not done already
go get code.google.com/p/go.net/websocket
go get github.com/jessevdk/go-flags
go get github.com/tarm/goserial

echo Building...

rem build
go install gocalcu

