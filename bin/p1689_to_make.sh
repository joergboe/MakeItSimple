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
usage="usage: ${command} input object depfile"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input file with dependency information according to P1689
	        object    : The primary_output (object) file of the TU
	        depfile   : The make dependency file to be extended with module dependency information

	Detect module dependencies for a translation unit in 'input' and append the
	module prerequisites in makefile format to 'depfile'. Every imported module
	is represented by a variable CXX_MOD_modulname_CMI. The CMI-file-name for 
	a given module must be provided by the make-script.
	The module dependency rule for a translation unit that imports modules has
	the form:
	
	        object : \${CXX_MOD_module1_CMI} \${CXX_MOD_module2_CMI}...

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
elif [[ $# -ne 3 ]]; then
	errexit "3 parameters required $# given!" 2
fi

inp="$1"
obj="$2"
dep="$3"

[[ -z "${inp}" || -z "${obj}" || -z "${dep}" ]] && errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1

my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found" 1

requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')

if [[ -n ${requires} ]]; then
	{
		echo -n "${obj} :"
		for module in ${requires}; do
			module_subst="${module//:/"-"}" # replace : with - in module names
			echo -n " \$(CXX_MOD_${module_subst//\$/\$\$}_CMI)"
		done
		echo
	} >> "${dep}"
fi

exit 0
