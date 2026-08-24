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
usage="usage: ${command} [-h|-v].. [--] depfile outfile name"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        depfile   : The input file with header dependencies in make format
	        outfile   : The output filename
	        name      : The header unit name

	    Options:
	        -h        : Help
	        -v        : Verbose

	Figure out the source file name from the first prerequisite of the first rule in 'depfile'.

	The output in one line of the form:

	        CXX_UNIT_SRC_LIST += unit-name;source

	    unit-name    : The unit name from command line
	    source       : The source file name from the first prerequisite in depfile
	
	Dollar symbols in names are replaced by two dollar symbols.

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
while getopts 'hv' arg; do
	case ${arg} in
		h) myhelp; exit 0;;
		v) verbose=1;;
		\? | *) echo "$usage"; exit 2;;
	esac
done
readonly verbose

[[ ${OPTIND} -gt 1 ]] && shift $((OPTIND-1))

if [[ $# -ne 3 ]]; then
	errexit "3 position parameters required $# given!" 2
fi

readonly inp="$1" out="$2" unit="$3"
[ -z ${verbose} ] || echo "Parameters '${inp}' '${out}' '${unit}'"

[[ -z "${inp}" || -z "${out}" || -z "${unit}" ]] && errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1


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
done < "${inp}"

[ -z ${verbose} ] || echo "prerequisites='${prerequisites}'"
src=
for preq in ${prerequisites}; do
	src="${preq}"
	break
done

[ -z ${verbose} ] || echo "src='${src}'"

# write variables to out
echo "CXX_UNIT_SRC_LIST += ${unit//\$/\$\$};${src//\$/\$\$}" > "${out}"

[ -z ${verbose} ] || echo "Done ${out}"
exit 0
