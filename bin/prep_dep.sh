#!/usr/bin/env bash

#some setup to be save
IFS=$' \t\n'
unset -f unalias
\unalias -a
unset -f command
set -o posix;
set -o errexit; set -o errtrace; set -o nounset; set -o pipefail
shopt -s nullglob

command=${0##*/}
usage="usage: ${command} depfile
       ${command} -h|--help"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        depfile   : The file with dependency information

	Read in the existing depfile and re-write prerequisites with escaped dollar
	symbols for secondary expansion.

	EOF
}

errexit() {
	local red=
	local end=
	if [ -t 2 ]; then
		red="\033[31m"
		end="\033[0m"
	fi
	echo -e "${red}ERROR: $1${end}" >&2
	[ "$2" == 2 ] && echo -e "\n${usage}\n" >&2
	exit "$2"
}

if [[  $# -ge 1 && ( $1 == '-h' || $1 == '--help' ) ]]; then
	myhelp
	exit 0
elif [[ $# -ne 1 ]]; then
	errexit "ERROR: 1 parameters required $# given!" 2
fi

readonly inp="$1"

[[ -z "${inp}" ]] \
	&& errexit "The parameter must not be empty!" 2
[ -r "${inp}" ] || errexit "Input file ${inp} is not readable!" 1

# Read existing dep-file and escape dependencies for secondary expansion
# Comments are not expected!
# Escaped backslashes at the end of the line are not considered!
readonly deptemp="${inp}~"
mv "${inp}" "${deptemp}"
touch "${inp}" # ensure at least an empty file

cont=
declare -i pos_colon no_backslash length x
while read -r; do
	if [[ -z ${cont} ]]; then
		pos_colon=-1
	fi
	length=${#REPLY}
	if (( length == 0 )); then
		echo >> "${inp}"
		cont=
	else 
		if (( pos_colon == -1 )); then
			no_backslash=0
			x=0
			while (( x < length )) && (( pos_colon == -1 )); do
				c="${REPLY:x:1}"
				if [[ $c == "\\" ]]; then
					no_backslash+=1
				elif [[ $c == ":" ]]; then
					if (( ( no_backslash % 2 ) == 0 )); then
						pos_colon=$x
					fi
					no_backslash=0
				else
					no_backslash=0
				fi
				(( x++ )) || :
			done
			if (( pos_colon == -1 )); then
				echo "${REPLY}" >> "${inp}"
			else
				targets="${REPLY:0:pos_colon}"
				prerequisites="${REPLY:pos_colon+1}"
				echo "${targets}:${prerequisites//\$/\$\$}" >> "${inp}"
			fi
		else
			echo "${REPLY//\$/\$\$}" >> "${inp}"
		fi
		if [[ ${REPLY: -1} == "\\" ]]; then # Note the space after colon
			cont=1
		else
			cont=
		fi
	fi
done < "${deptemp}"

[[ -n $REPLY ]] && errexit "Missing trailing newline" 1

rm "${deptemp}"

exit 0
