#!/bin/sh

go get github.com/fatih/color
go get -u -d github.com/magefile/mage
cd $GOPATH/src/github.com/magefile/mage && go run bootstrap.go