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

usage() {
	local command=${0##*/}
	cat <<-EOF

	usage: ${command} input object depfile

			Parameters:
			input            : Input file with dependency information according to P1689
			object           : The primary_output/object file of the TU
			depfile          : The make dependency file to be extended with module dependency information

	Append the module dependency prerequisites and only the prerequisites in makefile format from 'input' to 'depfile'.
	

	EOF
}

if [[  $# -ge 1 && ( $1 == '-h' || $1 == '--help' ) ]]; then
	usage
	exit 0
elif [[ $# -ne 3 ]]; then
	echo "ERROR: 3 parameters required $# given!" >&2
	usage >&2
	exit 2
fi

inp="$1"
obj="$2"
dep="$3"

[ -r "${inp}" ] || { echo "ERROR: input file ${inp} is not readable!"; exit 1; }

requires=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .requires then .requires[].[\"logical-name\"] else empty end" "${inp}")
number_provides=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .provides then .provides | length else empty end" "${inp}")
if [[ -n ${number_provides} && ${number_provides} != 1 ]]; then
	echo "ERROR: File $1 has invalid number of provides. Exit" >&2
	exit 1
fi

if [[ -n ${requires} ]]; then
	{
		echo -n "${obj}:"
		for module in ${requires}; do
			module_subst="${module//:/"-"}" # replace : with in module names
			echo -n " \$(CXX_MODULE2CMI_${module_subst//\$/\$\$})"
		done
		echo
	} >> "${dep}"
fi

exit 0
