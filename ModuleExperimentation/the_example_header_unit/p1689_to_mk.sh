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
usage="usage: ${command} [-h|-d|-v].. [--] input depfile unit object [source]"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input file with dependency information according to P1689
	        depfile   : The output make file. Module dependency information will be appended.
	        unit      : The unit name (may be - for a source file)
	        object    : The object/target name (primary output) in input
	        source    : The source file name (may be empty)

	    Options:
	        -h        : Help
	        -d        : Delete rules in 'depfile'
	        -v        : Verbose
	

	Detect module dependencies for a translation unit in 'input' and append the module dependencies 
	in Make format to 'depfile'.
	Json-file 'input' is scanned for an object with 'primary output' = 'object'. The provided module-name,
	the interface information and the required modules are detected.

	If parameter 'source' is empty or missing, the first prerequisite of the first rule in 'depfile' is output.
	
	The module dependency information is output in one line of the form:

	        CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += unit-name;object;source;provides;is_interface[;req1[;req2]]

	    unit-name    : The unit name from command line ('-' if input parameter is empty)
	    object       : The object/target
	    source       : The source file name from command line or from the first prerequisite in depfile
	    provides     : The module name if the source unit provides a c++ module; '-' otherwise
	    is_interface : 1 - if the source unit is a module interface unit; 0 - otherwise
	    req1, req2   : The names of the required modules
	
	Dollar symbols in names are replaced by two dollar symbols.
	The duplicate first slash in absolute header unit names is replaced by a single one.

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

verbose=
delete=
while getopts 'hdv' arg; do
	case ${arg} in
		h) myhelp; exit 0;;
		d) delete=1;;
		v) verbose=1;;
		\? | *) echo "$usage"; exit 2;;
	esac
done
readonly verbose delete

[[ ${OPTIND} -gt 1 ]] && shift $((OPTIND-1))

if [[ $# -lt 4 || $# -gt 5 ]]; then
	errexit "4 or 5 position parameters required $# given!" 2
fi

readonly inp="$1" dep="$2" unit="$3" obj="$4"
if [[ $# -gt 4 ]]; then
	src="$5"
else
	src=
fi
[ -z ${verbose} ] || echo "Options for ${dep}: delete='${delete}' src='${src}'"

[[ -z "${inp}" || -z "${dep}" || -z "${obj}" ]] && errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1

# Analyze P1689 file - search for an json-object with primary-output equals to $obj
my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found" 1

# Get provides and is_interface
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

# Get requires - the logical-names in requires array
requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')

if [[ -z ${src} ]]; then
	# Read existing dep-file and get the first prerequisite
	# Comment lines and escaped backslashes at the end of the line are not considered
	prerequisites=
	logical_line=
	while read -r; do
		[ -z ${verbose} ] || echo "REPL='${REPLY}'"
		if [[ ${REPLY: -1} == "\\" ]]; then # Note the space after colon
			logical_line+="${REPLY:0: -1}"
		else
			logical_line+="${REPLY}"
			[ -z ${verbose} ] || echo "logical_line='${logical_line}'"
			if [[ ${logical_line} =~ (.*):(.*) ]]; then
				prerequisites="${BASH_REMATCH[2]}"
				break
			fi
			logical_line=
		fi
	done < "${dep}"

	[ -z ${verbose} ] || echo "prerequisites='${prerequisites}'"
	for preq in ${prerequisites}; do
		src="${preq}"
		break
	done
fi

[ -z ${verbose} ] || echo "src='${src}'"

if [[ -n ${delete} ]]; then
	[ -z ${verbose} ] || echo "Move '${dep}' '${dep}~'"
	mv "${dep}" "${dep}~"
fi

[[ -z ${src} ]] && src='-'
[[ -z ${unit} ]] && unit='-'

{ # append variables to dep
	is_if=0
	provides_subst='-'
	if [[ -n ${provides} ]]; then
		if [[ -n ${is_interface} && ${is_interface} == 'true' ]]; then
			is_if=1
		fi
		provides_subst="${provides/#'//'/'/'}"
	fi

	echo -n "CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += ${unit//\$/\$\$};${obj//\$/\$\$};${src//\$/\$\$};${provides_subst//\$/\$\$};${is_if}"

	if [[ -n ${requires} ]]; then
		for module in ${requires}; do
			module_subst="${module/#'//'/'/'}"
			echo -n ";${module_subst//\$/\$\$}"
		done
	fi
	echo
} >> "${dep}"

[ -z ${verbose} ] || echo "Done ${dep}"
exit 0
