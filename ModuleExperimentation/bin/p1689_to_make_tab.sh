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
usage="usage: ${command} input depfile object source"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input        - file with dependency information according to P1689
	        depfile   : Input/Output - make dependency file to be extended with module dependency information
	        object    : The object file name (primary output)
	        source    : The source file name of the translation unit

	    Detects the module dependencies for a translation unit in 'input' and appends them to 'depfile' in make format.
	
	For each translation a line of the following form is emitted:

	        CXM_OBJ_SRC_MOD_IF_REQ_LIST += object;source;provides;is_interface(0/1)[;req1[;req2]]

	    object: the object file name
	    source: the source file name
	    provides: The module name if the source unit provides a c++ module; '-' otherwise
	    is_interface: 1 if the source unit is a module interface unit; 0 otherwise
	    req1, req2: the names of the required modules
	
	Dollar symbols in names are replaced by two dollar symbols. A hashmark is escaped with an backslash.

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

readonly inp="$1" dep="$2" obj="$3" src="$4"

[[ -z "${inp}" || -z "${dep}" || -z "${src}" || -z "${obj}" ]] && errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1

my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found" 1

provides=
is_interface=
number_provides=$(echo "${my_unit}" | jq -r "if .provides then .provides | length else empty end")
if [[ -n ${number_provides} ]]; then
	if [[ ${number_provides} = 0 ]]; then
		:
	elif [[ ${number_provides} = 1 ]]; then
		provides=$(echo "${my_unit}" | jq -r '.provides[0].["logical-name"]')
		is_interface=$(echo "${my_unit}" | jq -r '.provides[0].["is-interface"]')
	else
		errexit "File ${inp} has invalid number of provides. ${number_provides}" 1
	fi
fi

requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')

is_if=0
if [[ -n ${provides} ]]; then
	if [[ ${is_interface} = 'null' ]]; then
		is_if=1 # is-interface is optional and default is true
	elif [[ ${is_interface} = 'true' ]]; then
		is_if=1
	fi
	provides=${provides//\$/\$\$} # escape $ in make style
else
	provides='-'
fi

# append module deps to depfile
src_esc="${src//\$/\$\$}"
obj_esc="${obj//\$/\$\$}"
{
	# in assignment hash mark must be quoted
	# provides and requires should not contain #
	echo -n "CXM_OBJ_SRC_MOD_IF_REQ_LIST += ${obj_esc//#/\\#};${src_esc//#/\\#};${provides};${is_if}"

	if [[ -n ${requires} ]]; then
		for module in ${requires}; do
			echo -n ";${module//\$/\$\$}"
		done
	fi
	echo
} >> "${dep}"

exit 0
