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
usage="usage: ${command} [-h|-s|-d|(-e <extension>)].. [--] input depfile unit object [source]"

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
	        -s        : Re-write prerequisites and escaped dollar symbols for secondary expansion
	        -d        : Delete CMI-file prerequisites
	        -e        : The CMI file extension (default is .gcm)
	        -v        : Verbose
	

	Detect module dependencies for a translation unit in 'input' and append the module dependencies 
	in Make format to 'depfile'.
	Json-file 'input' is scanned for an object with 'primary output' = 'object'. The provided module-name,
	the interface information and the required modules are detected.

	If parameter 'source' is empty or missing, the the first prerequisite of the first depfile rule is output.
	
	The module dependency information is output in one line of the form:

	        CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += unit-name;object;source;provides;is_interface[;req1[;req2]]

	    unit-name    : The unit name from command line ('-' if input parameter is empty)
	    object       : The object/target
	    source       : The source file name from command line or from the first prerequisite in depfile
	    provides     : The module name if the source unit provides a c++ module; '-' otherwise
	    is_interface : 1 - if the source unit is a module interface unit; 0 - otherwise
	    req1, req2   : The names of the required modules
	
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

# Function: cut_off_cmi_deps()
# Arguments: $1 - dependencies
# Return: string in global var retval!
retval=
cut_off_cmi_deps() {
	if [[ -n ${delete} ]]; then
		retval=
		for temp in $1; do
			if [[ ${temp} != *${cmi_extension} ]]; then
				if [ -z "${retval}" ]; then
					retval="${temp}"
				else
					retval="${retval} ${temp}"
				fi
			fi
		done
	else
		retval="$1"
	fi
	return 0
}

# Function: mangle_module
# This function:
#     replaces a ':' by '-' in a named module (no path component)
#     Removes the duplicated slash in a system header unit name
#     Replaces dots by commas in the path component of user header unit name
retval=
mangle_module() {
	case $1 in
		//*)
			retval=${1/#///"/"};;
#		./*)
#			retval=
#			save_ifs="$IFS"
#			IFS='/'
#			local dir=
#			for dir in $1; do
#				[ -z "${retval}" ] || retval+="/"
#				if [ "${dir}" = '.' ]; then
#					retval+=','
#				elif [ "${dir}" = '..' ]; then
#					retval+=',,'
#				else
#					retval+="${dir}"
#				fi
#			done
#			IFS="${save_ifs}";;
		*)
			retval=${1//:/"-"}
	esac
	return 0
}

# Arguments: $1 - module name
# Return: string in global var retval

secondary=
delete=
cmi_extension='.gcm'
verbose=
while getopts 'hsde:v' arg; do
	case ${arg} in
		h) myhelp; exit 0;;
		s) secondary=1;;
		d) delete=1;;
		e) cmi_extension="${OPTARG}";;
		v) verbose=1;;
		\? | *) echo "$usage"; exit 2;;
	esac
done
readonly secondary delete cmi_extension verbose

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
[ -z ${verbose} ] || echo "Options for ${dep}: secondary=${secondary} delete=${delete} cmi_extension=${cmi_extension}"
[ -z ${verbose} ] || echo "src='${src}'"

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

# 
if [[ -z ${src} || -n ${secondary} || -n ${delete} ]]; then
	rewrite=1
else
	rewrite=
fi
[ -z ${verbose} ] || echo "rewrite='${rewrite}'"

if [[ -n ${rewrite} ]]; then
	readonly deptemp="${dep}~"
	mv "${dep}" "${deptemp}"
	touch "${dep}" # ensure at least an empty file

	# Read existing dep-file and get the first prerequisite
	# Comment lines and escaped backslashes at the end of the line are not considered
	cont=
	declare -i pos_colon no_backslash length x
	targets=
	prerequisites=
	all_prerequisites=
	first_prerequisites=
	while read -r; do
		[ -z ${verbose} ] || echo "*** cont='${cont}' - REPL='${REPLY}'"
		if [[ -z ${cont} ]]; then
			pos_colon=-1
		fi
		length=${#REPLY}
		if (( length == 0 )); then
			cont=
			echo >> "${dep}"
		else 
			if (( pos_colon == -1 )); then
				no_backslash=0
				x=0
				while (( x < length )) && (( pos_colon == -1 )); do
					c="${REPLY:x:1}"
					if [[ $c == "\\" ]]; then
						no_backslash+=1
					elif [[ $c == ":" ]]; then
						if (( ( no_backslash % 2 ) == 0 )); then
							pos_colon=$x
						fi
						no_backslash=0
					else
						no_backslash=0
					fi
					(( x++ )) || :
				done
				if (( pos_colon == -1 )); then
					[ -z ${verbose} ] || echo "    No rule yet - ${REPLY}"
					echo "${REPLY}" >> "${dep}"
				else
					targets="${REPLY:0:pos_colon}"
					prerequisites="${REPLY:pos_colon+1}"
					all_prerequisites="${prerequisites}"
					[ -z ${verbose} ] || echo "    Rule I - '${targets} : ${prerequisites}'"
					cut_off_cmi_deps "${targets}"
					targets="${retval}"
					if [[ -n ${secondary} ]]; then
						pr2="${prerequisites//\$/\$\$}"
					else
						pr2="${prerequisites}"
					fi
					cut_off_cmi_deps "${pr2}"
					[ -z ${verbose} ] || echo "    Rule O - '${targets} : ${retval}'"
					echo "${targets} : ${retval}" >> "${dep}"
				fi
			else
				all_prerequisites+=" ${REPLY}"
				[ -z ${verbose} ] || echo "    Prerequisites I - '${REPLY}'"
				if [[ -n ${secondary} ]]; then
					pr2="${REPLY//\$/\$\$}"
				else
					pr2="${REPLY}"
				fi
				cut_off_cmi_deps "${pr2}"
				[ -z ${verbose} ] || echo "    Prerequisites O - '${retval}'"
				echo " ${retval}" >> "${dep}"
			fi
			if [[ ${REPLY: -1} == "\\" ]]; then # Note the space after colon
				cont=1
			else
				cont=
				if [[ -n ${targets} && -n ${all_prerequisites} && -z ${first_prerequisites} ]]; then
					first_prerequisites="${all_prerequisites}"
				fi
			fi
		fi
	done < "${deptemp}"

	[ -z ${verbose} ] || echo "first_prerequisites='${first_prerequisites}'"
	if [[ -z ${src} ]]; then
		for preq in ${first_prerequisites}; do
			src="${preq}"
			break
		done
	fi
fi

[ -z ${verbose} ] || echo "src='${src}'"

[[ -z ${src} ]] && src='-'
[[ -z ${unit} ]] && unit='-'

{ # append variables to dep
	is_if=0
	provides_subst='-'
	if [[ -n ${provides} ]]; then
		if [[ -n ${is_interface} && ${is_interface} == 'true' ]]; then
			is_if=1
		fi
		mangle_module "${provides}"
		provides_subst="${retval}"
	fi
	echo -n "CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += ${unit//\$/\$\$};${obj//\$/\$\$};${src//\$/\$\$};${provides_subst//\$/\$\$};${is_if}"

	if [[ -n ${requires} ]]; then
		for module in ${requires}; do
#			module_subst="${module//:/"-"}" # replace : with - in module names
			mangle_module "${module}"
			module_subst="${retval}"
			echo -n ";${module_subst//\$/\$\$}"
		done
	fi
	echo
} >> "${dep}"

[ -z ${verbose} ] || echo "Done ${dep}"
exit 0
