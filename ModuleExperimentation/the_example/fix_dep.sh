#!/usr/bin/env bash

#some setup to be save
IFS=$' \t\n'
#some recomended security settings
unset -f unalias
\unalias -a
unset -f command
#more setting to be save
set -o posix;
set -o errexit; set -o errtrace; set -o nounset; set -o pipefail
shopt -s nullglob

command=${0##*/}
usage="usage: ${command} input depfile"

[[ $# -eq 2 ]] || { echo "${usage}"; exit 2; }

#rm -f "$2"

{
	while read -r; do
		echo "${REPLY/#.PHONY:/.INTERMEDIATE :}"
	done < "$1"
} > "$2"
