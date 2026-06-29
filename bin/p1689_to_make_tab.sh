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
usage="usage: ${command} input depfile source object"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input file with dependency information according to P1689
	        depfile   : The output make file. Module dependency information will be appended.
	        source    : The source file name of the translation unit
	        object    : The object file name (primary output)

	Detect module dependencies for a translation unit in 'input' and create the depfile
	in Make format. The depfile can contain 2 tables.
	
	For each translation a line of the following form is emitted:

	        CXX_OBJ_SRC_MOD_IF_REQ_LIST += object;source;provides;is_interface(0/1)[;req1[;req2]]

	    object: the object file name
	    source: the source file name
	    provides: The module name if the source unit provides a c++ module; '-' otherwise
	    is_interface: 1 if the source unit is a module interface unit; 0 otherwise
	    req1, req2: the names of the required modules
	
	A colon in a module name (module partitions) is replaced by a dash. Dollar
	symbols in names are replaced by two dollar symbols.

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
elif [[ $# -ne 4 ]]; then
	errexit "4 parameters required $# given!" 2
fi

readonly inp="$1" dep="$2" src="$3" obj="$4"

[[ -z "${inp}" || -z "${dep}" || -z "${src}" || -z "${obj}" ]] && errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1

my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found" 1

number_provides=$(echo "${my_unit}" | jq -r "if .provides then .provides | length else empty end")
if [[ -z ${number_provides} || ${number_provides} -eq 0 ]]; then
	provides=
	is_interface=
elif [[ ${number_provides} != 1 ]]; then
	errexit "File ${inp} has invalid number of provides. ${number_provides}" 1
else
	provides=$(echo "${my_unit}" | jq -r '.provides[0].["logical-name"]')
	is_interface=$(echo "${my_unit}" | jq -r 'if .provides[0].["is-interface"] then .provides[0].["is-interface"] else empty end')
fi

requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')

{
	is_if=0
	provides_subst='-'
	if [[ -n ${provides} ]]; then
		if [[ -n ${is_interface} && ${is_interface} == 'true' ]]; then
			is_if=1
		fi
		provides_subst="${provides//:/"-"}"
	fi
	echo -n "CXX_OBJ_SRC_MOD_IF_REQ_LIST += ${obj//\$/\$\$};${src//\$/\$\$};${provides_subst//\$/\$\$};${is_if}"

	if [[ -n ${requires} ]]; then
		for module in ${requires}; do
			module_subst="${module//:/"-"}" # replace : with - in module names
			echo -n ";${module_subst//\$/\$\$}"
		done
	fi
	echo
} >> "${dep}"

exit 0
