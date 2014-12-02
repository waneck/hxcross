#!/usr/bin/env bash

# simple utility to check the permissions of a directory, create it if needed with
# the needed credentials, and execute a command afterwards - with the needed credentials as well

QUIET=0
if [ ! -z "$1" ] && [ "$1" = "-q" ]; then
	shift
	QUIET=1
fi

DEST=$1

if [ -z "$DEST" ]; then
	echo "Usage: install.sh [-q] <dir> [cmd [arg1 [arg2 ... [argn]]]]"
	exit 1
fi

shift

DIR="$DEST"
while [ ! -e "$DIR" ] && [ ! -z "$DIR" ]; do
	DIR=$(dirname "$DIR")
done

if [ -w "$DIR" ]; then
	mkdir -p "$DEST" || exit 1
	if [ ! -z "$1" ]; then
		[ $QUIET -eq 0 ] && echo "$@"
		eval "$@" || exit 2
	fi
else
	[ $QUIET -eq 0 ] && echo "sudo mkdir -p "$DEST""
	sudo mkdir -p "$DEST" || exit 1
	if [ ! -z "$1" ]; then
		[ $QUIET -eq 0 ] && echo "sudo "$@""
		sudo "$@" || exit 2
	fi
fi
