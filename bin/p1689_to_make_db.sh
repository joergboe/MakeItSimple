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
usage="usage: ${command} depdb dep_ext src_ext obj_ext [input [input]..]"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        depdb       : The dependency database in makefile format
	        dep_ext     : The extension of the structured dependency (input) files (.ddi)
	        src_ext     : The extension for source files.
	        obj_ext     : The extension for object files.
	        input       : Input files with structured dependency information according to P1689

	Dump the module dependency database in makefile format from all input files
	to 'depdb'.
	The source filename is formed from the name of the input file by removing the
	dep_ext and appending the src_ext. The object filename (primary-output) is
	formed from the name of the input file by removing the dep_ext and appending
	the obj_ext.
	For each translation unit that exports a module, a triple of the following
	form is emitted:

	        CXX_SRC_MOD_IF_LIST += source;provides;is_interface(0/1)

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
elif [[ $# -lt 4 ]]; then
	errexit "Minimum 4 parameter required $# given!" 2
fi

depdb="$1"
dep_ext="$2"
src_ext="$3"
obj_ext="$4"
shift 4

[[ -z "$depdb" ]] && errexit "depdb must not be empty" 2
[[ -z "$dep_ext" ]] && errexit "dep_ext must not be empty" 2

rm -f "${depdb}"
# Provide the output file if no input files are given
echo "# Automatic generated module dependency database" > "${depdb}"

while [[ $# -ge 1 ]]; do
	inp="$1"; shift
	[ -r "${inp}" ] || errexit "Input file ${inp} is not readable!" 1
	[[ ${inp} == *${dep_ext} ]] || errexit "Input file ${inp} does not match *${dep_ext}" 2

	stem="${inp%"${dep_ext}"}"
	src="${stem}${src_ext}"
	obj="${stem}${obj_ext}"

	my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
	[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found"  1

	number_provides=$(echo "${my_unit}" | jq -r "if .provides then .provides | length else empty end")
	if [[ -z ${number_provides} ]]; then
		continue
	elif [[ ${number_provides} != 1 ]]; then
		errexit "File ${inp} has invalid number of provides." 1
	fi

	provides=$(echo "${my_unit}" | jq -r '.provides[0].["logical-name"]')
	is_interface=$(echo "${my_unit}" | jq -r 'if .provides[0].["is-interface"] then .provides[0].["is-interface"] else empty end')

	[[ -z ${provides} ]] && errexit "Logic error" 1
	{
		is_if=0
		if [[ -n ${is_interface} && ${is_interface} == 'true' ]]; then
			is_if=1
		fi
		provides_subst="${provides//:/"-"}"
		echo "CXX_SRC_MOD_IF_LIST += ${src//\$/\$\$};${provides_subst//\$/\$\$};${is_if}"
	} >> "${depdb}"

done

exit 0
