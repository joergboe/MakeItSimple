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
usage="usage: ${command} [-h|-v].. [--] mapper curdir depfile outfile"

myhelp() {
	cat <<-EOF

	Add the rule for the header unit dependencies to the depfile.

	${usage}

	    Parameters:
	        mapper       : A file with the system header database <source> <cmi>
	        curdir       : Current directory from make (without trailing slash!).
	        depfile      : The input file with header dependencies in make format
	        outfile      : The output filename

	    Options:
	        -h        : Help
	        -v        : Verbose

	The script scans the dependencies of a header unit (the first rule). If a dependency exists in the system header
	or user header database, a rule with the dependend cmi file is added:
	    <my cmi> : <dpendency cmi1> <dpendency cmi2>

	Dollar symbols in names are replaced by two dollar symbols.

	EOF
}

errexit() {
	error "$1"
	[ "$2" == 2 ] && echo -e "\n${usage}\n" >&2
	exit "$2"
}

error() {
	local red=
	local end=
	if [ -t 2 ]; then
		red="\033[31m"
		end="\033[0m"
	fi
	echo -e "${red}${command} : ERROR: $1${end}" >&2
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

if [[ $# -ne 4 ]]; then
	errexit "4 position parameters required $# given!" 2
fi

readonly mapper="$1" curdir="$2" inp="$3" outp="$4"
[ -z ${verbose} ] || echo "Parameters '${mapper}' '${curdir}' '${inp}' '${outp}'"

[[ -z ${mapper} || -z ${curdir} || -z "${inp}" || -z "${outp}" ]] && errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1
[[ ${curdir} == */ ]] && errexit "curdir must not end with /!" 2

# read database: source->cmi
declare -A map_arr=()
while read -r -a line_arr; do
	[ -z ${verbose} ] || declare -p line_arr
	if [[ ${#line_arr[*]} -eq 2 ]]; then
		temp="${line_arr[0]/#.\//}" # revert change src -> logical name
		map_arr["${temp}"]="${line_arr[1]}"
	else
		errexit "Ignore line ${line_arr[*]}" 1
	fi
done < "${mapper}"
[ -z ${verbose} ] || declare -p map_arr

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

rule=
prerequisite_found=
declare -i count=0
for preq in ${prerequisites}; do
	[ -z ${verbose} ] || echo "preq='${preq}'"
	if [[ count -eq 0 ]]; then
		set +o nounset
		if [[ -n ${map_arr["${preq}"]} ]]; then
			rule="${map_arr["${preq}"]} :"
		else
			errexit "Source #1 ${preq} not found in mapper!" 1
		fi
		set -o nounset
	else
		set +o nounset
		temp="${map_arr["${preq}"]}"
		if [[ -n ${temp} ]]; then
			rule+=" ${temp}"
			prerequisite_found=1
		elif [[ ${preq} == /* ]]; then # preq is absolute - check whether we have the relative pathname in cache
			relative_path="$(realpath "${preq}")"
			temp="${map_arr["${relative_path}"]}"
			if [[ -n ${temp} ]]; then
				rule+=" ${temp}"
				prerequisite_found=1
			fi
		else # preq is relative - check whether we have the absolute pathname in cache
			abs_path="${curdir}/${preq}"
			temp="${map_arr["${abs_path}"]}"
			if [[ -n ${temp} ]]; then
				rule+=" ${temp}"
				prerequisite_found=1
			fi
		fi
		set -o nounset
	fi
	(( count++ )) && :
done
[ -z ${verbose} ] || echo "rule '${rule}'"

cp "${inp}" "${outp}"
if [[ -n ${prerequisite_found} ]]; then
	echo "${rule}" >> "${outp}"
else
	[ -z ${verbose} ] || echo "No rule output"
fi

[ -z ${verbose} ] || echo "Done ${outp}"
exit 0
