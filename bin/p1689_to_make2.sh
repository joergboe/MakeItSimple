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

	usage: ${command} input source object cmi_extension cache_dir depfile

			Parameters:
			input            : Input file with dependency information according to P1689
			source           : The TU source file
			object           : The primary_output/object file of the TU
			cmi_extension    : The file extension of the cmi file
			cache_dir        : The cache directory for cmi files
			depfile          : The make dependency file to be extended with module dependency information

	Append the module dependency rules in makefile format from 'input' to 'depfile'. Escape prerequisites for secondary
	expansion.

	EOF
}

if [[  $# -ge 1 && ( $1 == '-h' || $1 == '--help' ) ]]; then
	usage
	exit 0
elif [[ $# -ne 6 ]]; then
	echo "ERROR: 6 parameters required $# given!" >&2
	usage >&2
	exit 2
fi

inp="$1"
src="$2"
obj="$3"
cmi_ext="$4"
cache="$5"
dep="$6"

[ -r "${inp}" ] || { echo "ERROR: input file ${inp} is not readable!"; exit 1; }

requires=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .requires then .requires[].[\"logical-name\"] else empty end" "${inp}")
number_provides=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .provides then .provides | length else empty end" "${inp}")
if [[ -n ${number_provides} && ${number_provides} != 1 ]]; then
	echo "ERROR: File $1 has invalid number of provides. Exit" >&2
	exit 1
fi
provides=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .provides then .provides[0].[\"logical-name\"] else empty end" "${inp}")
is_interface=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .provides then if .provides[0].[\"is-interface\"] then .provides[0].[\"is-interface\"] else empty end else empty end" "${inp}")

if [[ -n ${requires} ]]; then
	{
		echo -n "${obj} :"
		for module in ${requires}; do
			module_subst="${module//:/"-"}" # replace : with in module names
			echo -n " \$\$(CXX_MOD_${module_subst//\$/\$\$\$\$}_CMI)"
		done
		echo
	} >> "${dep}"
fi

if [[ -n ${provides} ]]; then
	{
		is_if=0
		if [[ -n ${is_interface} && ${is_interface} == 'true' ]]; then
			is_if=1
		fi
		provides_subst="${provides//:/"-"}"
		echo "CXX_SRC_MOD_CMI_IF_LIST += ${src//\$/\$\$};${provides_subst//\$/\$\$};${cache//\$/\$\$}/${provides_subst//\$/\$\$}.${cmi_ext};${is_if}"
	} >> "${dep}"
fi

exit 0
