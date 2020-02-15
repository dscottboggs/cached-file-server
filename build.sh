#!/bin/sh

if test "$1" = -d || test "$1" = --dev; then
	MODE=""
else
	MODE=--release
fi

docker run --rm -it -v $PWD:/app -w /app jrei/crystal-alpine crystal build --static $MODE -obin/server src/run.cr
