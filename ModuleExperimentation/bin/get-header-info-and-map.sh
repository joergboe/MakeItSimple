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
usage="usage: ${command} [-h|-v].. [--] depfile outfile name cache ext kind"

myhelp() {
	cat <<-EOF

	Get source filename information from depfile and provide the CMI filename mapping.

	${usage}

	    Parameters:
	        depfile   : The input file with header dependencies in make format
	        outfile   : The output filename
	        name      : The header unit name
	        cache     : The CMI cache directory (without trailing slash!)
	        ext       : The CMI filename extension (without dot!)
	        kind      : system or user

	    Options:
	        -h        : Help
	        -v        : Verbose

	Figure out the source file name from the first prerequisite of the first rule in 'depfile' and append the
	CMI file name for the header unit.

	The output in one line of the form:

	        CXM_UNIT_SRC_MOD_CMI_KIND_LIST += <unit name>;<source name>;<logical module>;<cmi name>;<kind>

	    unit name      : The unit name from command line
	    source name    : The source file name from the first prerequisite in depfile
	    logical module : The logical module name. The source name if the source path is absolute. If the source path is
	                     relative and does not begin with a dot, a ‘./’ directory is prepended.
	    cmi            : The CMI file name: <cache>/<logical module>.<ext>. Internal ‘..’ or '.' components are
	                     translated to ‘,,’ or '.' in logical module.

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
	echo -e "${red}${command} : ERROR: $1${end}" >&2
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

if [[ $# -ne 6 ]]; then
	errexit "6 position parameters required $# given!" 2
fi

readonly inp="$1" out="$2" unit="$3" cache="$4" ext="$5" kind="$6"
[ -z ${verbose} ] || echo "Parameters '${inp}' '${out}' '${unit}' '${cache}' '${ext}' '${kind}'"

[[ -z ${inp} || -z ${out} || -z ${unit} || -z ${cache} || -z ${kind} ]] \
				&& errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1
[[ ${cache} == */ ]] && errexit "Cache directory must not have the trailing /" 2


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

if [[ ${src} == /* || ${src} == .* ]]; then
	logname="${src}"
else
	logname="./${src}"
fi
[ -z ${verbose} ] || echo "logname='${logname}'"

# replace /../ with /,,/ in cmi file component
temp="${logname//\/..\//\/,,\/}"
[ -z ${verbose} ] || echo "temp='${temp}'"

# replace /./ with /,/ in cmi file component
temp2="${temp//\/.\//\/,\/}"
[ -z ${verbose} ] || echo "temp2='${temp2}'"

# replace ./ with ,/ at beginning
temp3="${temp2/#.\//,\/}"
[ -z ${verbose} ] || echo "temp3='${temp3}'"

# complete cmi name
if [[ ${temp3} == /* ]]; then
	cmi="${cache}/.${temp3}.${ext}" # emulate the default gcc mapper
else
	cmi="${cache}/${temp3}.${ext}"
fi
[ -z ${verbose} ] || echo "cmi='${cmi}'"

# write variables to out
echo "CXM_UNIT_SRC_MOD_CMI_KIND_LIST += ${unit//\$/\$\$};${src//\$/\$\$};${logname//\$/\$\$};${cmi//\$/\$\$};${kind}" \
	> "${out}"

[ -z ${verbose} ] || echo "Done ${out}"
exit 0
