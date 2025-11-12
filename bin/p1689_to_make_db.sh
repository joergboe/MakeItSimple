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

	usage: ${command} cmi_extension cache_dir depfile input [input [input]]

			Parameters:
			cmi_extension    : The file extension of the cmi file
			cache_dir        : The cache directory for cmi files
			depfile          : The make dependency file to be extended with module dependency information
			input            : Input files with dependency information according to P1689

	Dump the module dependency database in makefile format from all input files to 'depfile'.

	EOF
}

if [[  $# -ge 1 && ( $1 == '-h' || $1 == '--help' ) ]]; then
	usage
	exit 0
elif [[ $# -lt 3 ]]; then
	echo "ERROR: Minimum 3 parameters required $# given!" >&2
	usage >&2
	exit 2
fi

cmi_ext="$1"
cache="$2"
dep="$3"
shift 3

rm -f "${dep}"
touch "${dep}"    # Create an empty file if no input files are given

while [[ $# -ge 1 ]]; do
	inp="$1"; shift
	[ -r "${inp}" ] || { echo "ERROR: input file ${inp} is not readable!"; exit 1; }

	src="${inp%.ddi}"
	obj="${src}.o"

	provides=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .provides then .provides[0].[\"logical-name\"] else empty end" "${inp}")
	is_interface=$(jq -r ".rules[] | select(.[\"primary-output\"] == \"${obj}\") | if .provides then if .provides[0].[\"is-interface\"] then .provides[0].[\"is-interface\"] else empty end else empty end" "${inp}")

	if [[ -n ${provides} ]]; then
		{
			#echo "${5}/${provides}.c++-module : ${cmi}"
			if [[ -n ${is_interface} && ${is_interface} == 'true' ]]; then
				echo "CXX_MODULE_INTERFACE_UNITS += ${src//\$/\$\$}"
			fi
			provides_subst="${provides//:/"-"}"
			echo "CXX_CMI_FILES += ${cache//\$/\$\$}/${provides_subst//\$/\$\$}.${cmi_ext}"
			echo "CXX_MODULES += ${provides_subst//\$/\$\$}"
			echo "CXX_MODULE_SOURCES += ${src//\$/\$\$}"
			echo "CXX_SOURCE2MODULE_${src//\$/\$\$} := ${provides_subst//\$/\$\$}"
			echo "CXX_SOURCE2CMI_${src//\$/\$\$} := ${cache//\$/\$\$}/${provides_subst//\$/\$\$}.${cmi_ext}"
			echo "CXX_MODULE2CMI_${provides_subst//\$/\$\$} := ${cache//\$/\$\$}/${provides_subst//\$/\$\$}.${cmi_ext}"
			echo "CXX_MODULE2SOURCE_${provides_subst//\$/\$\$} := ${src//\$/\$\$}"
		} >> "${dep}"
	fi
done

exit 0
