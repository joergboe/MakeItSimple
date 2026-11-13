#!/usr/bin/env bash

# Some recommended security settings:
unset -f unalias
\unalias -a
unset -f command
IFS=$' \t\n'
#set -o posix;
set -f  # Disable pathname expansion.
set -o errexit; set -o errtrace; set -o nounset; set -o pipefail

command=${0##*/}
usage="usage: ${command} [-h|-v].. [--] input depfile object source"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input file with module dependency information according to P1689
	        depfile   : Input/Output file make dependency file to be extended with module dependency information
	        object    : Primary_output (object) of the Translation Unit
	        source    : Source file name

	    Options:
	        -h             : Help
	        -v             : Verbose
	        -m <mdbfile>   : The output file for the module dependency information in make format. If this
	                         option has an empty value or is not specified, the content is appended to 'depfile'.
	        -f             : Add the 'cmitarget to target list in the first rule in 'depfile' if the Translation
	                         Unit provides a module.
	        -s             : Append a Module Dependency Rule to 'depfile' if the Translation Unit requires modules.
	        -c <cmittempl> : The CMI-Target Template. If Module Substitution String is non empty, the Module
	                         Substitution String is replaced by the Provided Module. (Default: \$(call mmap,mod))
	        -u             : Substitute the string 'mod' in CMI-Target Template with the Provided Module.
	        -r <prereq>    : The Required Module Prerequisite Template. The string 'mod' is replaced by the name
	                         of the required module. Colon in module name is replaced by a dash.
	                         (Default: \$(CXX_MOD_mod_CMI))
	        -p             : Append the module dependencies in 'mdbfile' (CXX_SRC_OBJ_MOD_IF_REQ_LIST)
	        -y             : Prepare prerequisites in rules for Secondary Expansion.

	1) The script scans the Structured Module Dependency Information of a Translation Unit in 'input'
	   and determines the Provided Module if any, the flag Is Interface and the list of Required Modules.

	2) If the TU provides a module, a CMI-Target is determined from CMI-Target Template.
	   If option '-u' is not set, the CMI-Target Template is escaped according to the rules of GNU-make for
	   targets and used as CMI-Target.
	   If option '-u' is set, string 'mod' in CMI-Target Template is substituted with the Provided Module
	   and used as CMI-Target. Dollar symbols in module name are replaced by two dollar symbols. We assume
	   that the whole CMI-Target Template spans a functional context. Colon in module name is passed unchanged.

	3) If the -f option is specified and the TU provides a module, the first rule in 'depfile' is prefixed
	   with CMI-Target.

	4) If the Translation Unit requires modules, a second rule with module dependencies is appended to
	   'depfile'.
	   For non module units this rule the form:
	        object : \$(CXX_MOD_require1_CMI) \$(CXX_MOD_require2_CMI)...
	   For non module units this rule the form::
	        cmitarget object : \$(CXX_MOD_require1_CMI) \$(CXX_MOD_require2_CMI)...
	   Dollar symbols in module name are replaced by two dollar symbols.
	   Colon in module name (module partitions) is replaced by a dash.
	   Period (submodules) is passed as is.
	   Other special characters like ‘:’, ‘#’, ‘=’, or white-space are not allowed in make variable names.
	   This is acceptable, since C++ module names cannot contain those characters.
	   Characters from the extended character set are allowed in make variable names.
	   'object' is escaped according to the rules of GNU-make for targets.

	5) If 'mdbfile' has an empty value or is not specified, 'mdbfile' gets the value of 'depfile'.
	
	6) If the option -y is specified, dependencies in rules are escaped for Secondary Expansion.
	   This means that dollar signs are replaced once again by two dollar signs.

	7) Dump the module dependency database in makefile format to 'mdbfile'.
	   If option '-p' is not set:
	   For each translation unit that provides a module, a quadruple of the following
	   form is emitted:
	        CXX_SRC_OBJ_MOD_IF_LIST += source;object;provides;is_interface(0/1)
	   For a non module translation unit, the following triple is emitted:
	        CXX_SRC_OBJ_MOD_IF_LIST += source;object;-;0
	   If option '-p' is set:
	   For each translation unit that provides a module, a variable of the following
	   form is emitted:
	        CXX_SRC_OBJ_MOD_IF_REQ_LIST += source;object;provides;is_interface[;requires1[..]]
	   For a non module translation unit, the following triple is emitted:
	        CXX_SRC_OBJ_MOD_IF_REQ_LIST += source;object;-;0
	   Dollar symbols are replaced by two dollar symbols.
	   Colon in module name is replaced by a dash. Period is passed as is.
	   In assignments the hashmark in source filenames is escaped by a backslash as requird by make.
	EOF
}

# Print a red error message to stderr and exit. If the return code is 2 'usage' precedes the error message.
# Parameters: $1 - Error message
#             $2 - Return code
errexit() {
	error "(${BASH_LINENO[0]}) $1"
	[ "$2" == 2 ] && echo -e "\n${usage}\n" >&2
	exit "$2"
}

# Print a red error message to stderr.
# Parameter: $1 - The message to print.
error() {
	local red=
	local end=
	if [ -t 2 ]; then
		red="\033[31m"
		end="\033[0m"
	fi
	echo -e "${red}${command} : ERROR: $1${end}" >&2
}

# Escape for rule.
# Parameters: $1 - Input string
#             $2 - A space follows if this parameter is non empty.
result=
escape_for_rule() {
	result=
	local -i i
	local c
	local -i slashes=0
	for ((i=0;i<${#1};i++)); do
		c="${1:${i}:1}"
		case "${c}" in
			\\)
				((slashes++)) || : ;;
			\$)
				result+="${c}"
				slashes=0;;
			\ |\	|\#|:)
				((slashes++)) || : # 2*slashes + 1 must precede a special character.
				while ((slashes--)); do result+=\\; done;&
				# FALLTHROUGH
			*)
				slashes=0;;
		esac
		result+="${c}"
	done
	if [ -n "$2" ]; then
		# If space follows we must double the number of backslashes.
		while ((slashes--)); do result+=\\; done
	fi
}

escape_for_assign() {
	result=
	local -i i
	local c
	local -i slashes=0
	for ((i=0;i<${#1};i++)); do
		c="${1:${i}:1}"
		case "${c}" in
			\\)
				((slashes++)) || : ;;
			\$)
				result+="${c}"
				slashes=0;;
			\#)
				((slashes++)) || : # 2*slashes + 1 must precede a special character.
				while ((slashes--)); do result+=\\; done;&
				# FALLTHROUGH
			*)
				slashes=0;;
		esac
		result+="${c}"
	done
}

verbose=
mdbfile=
prefix_first_rule=
add_module_dep_rule=
cmi_target_templ=\$\(call\ mmap,mod\)
subs_mod=
prereq_templ=\$\(CXX_MOD_mod_CMI\)
append_module_deps=
secondary_exp=
while getopts 'hvm:fsc:ur:py' arg; do
	case ${arg} in
		h) myhelp; exit 0;;
		v) verbose=1;;
		m) mdbfile="${OPTARG}";;
		f) prefix_first_rule=1;;
		s) add_module_dep_rule=1;;
		c) cmi_target_templ="${OPTARG}";;
		u) subs_mod=1;;
		r) prereq_templ="${OPTARG}";;
		p) append_module_deps=1;;
		y) secondary_exp=1;;
		*) echo "$usage"; exit 2;;
	esac
done
readonly verbose prefix_first_rule add_module_dep_rule cmi_target_templ subs_mod prereq_templ append_module_deps \
    secondary_exp

[[ ${OPTIND} -gt 1 ]] && shift $((OPTIND-1))

if [[ $# -ne 4 ]]; then
	errexit "4 parameters required $# given!" 2
fi

readonly inp="$1" dep="$2" obj="$3" src="$4"
if [[ -n "${verbose}" ]]; then
	for x in mdbfile prefix_first_rule add_module_dep_rule cmi_target_templ subs_mod prereq_templ append_module_deps secondary_exp; do
		echo "${x}='${!x}'"
	done
fi

[[ -z "${inp}" || -z "${dep}" || -z "${obj}" || -z "${src}" ]] \
	&& errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1
[[ -r "${dep}" ]] || errexit "Input file ${dep} is not readable!" 1

one_output_file=
if [[ -z ${mdbfile} ]]; then
	one_output_file=1
	mdbfile="${dep}"
fi
readonly mdbfile
[ -z "${verbose}" ] || echo "one_output_file=${one_output_file}"

# Search for a rule where 'primary-output' matches 'obj'.
my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found" 1

provides=
is_interface=
number_provides=$(echo "${my_unit}" | jq -r "if .provides then .provides | length else empty end")
if [[ -n ${number_provides} ]]; then
	if [[ ${number_provides} = 0 ]]; then
		:
	elif [[ ${number_provides} = 1 ]]; then
		provides=$(echo "${my_unit}" | jq -r '.provides[0].["logical-name"]')
		is_interface=$(echo "${my_unit}" | jq -r '.provides[0].["is-interface"]')
	else
		errexit "File ${inp} has invalid number of provides." 1
	fi
fi

is_if=0
if [[ -n ${provides} ]]; then
	if [[ ${is_interface} = 'null' ]]; then
		is_if=1 # is-interface is optional and default is true
	elif [[ ${is_interface} = 'true' ]]; then
		is_if=1
	fi
	provides=${provides//\$/\$\$} # escape $ in make style
fi
[ -z "${verbose}" ] || echo "number_provides=${number_provides} provides='${provides}'"
[ -z "${verbose}" ] || echo "is_if='${is_if}'"

requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')
if [[ -n ${requires} ]]; then
	requires="${requires//\$/\$\$}"
fi
[ -z "${verbose}" ] || echo "requires=${requires}"

# Provide CMI-Target
if [[ -n ${prefix_first_rule} || -n ${add_module_dep_rule} ]]; then
	if [[ -n ${provides} ]]; then
		if [[ -n ${subs_mod} ]]; then
			readonly cmitarget="${cmi_target_templ//mod/"${provides}"}"
		else
			escape_for_rule "${cmi_target_templ}" 1
			readonly cmitarget="${result}"
		fi
	else
		readonly cmitarget=
	fi
	[ -z "${verbose}" ] || echo "cmitarget=${cmitarget}"
fi

# Preparing the output depfile.
readonly deptemp="${dep}~"
mv "${dep}" "${deptemp}"
echo -n > "${dep}" # Ensure an empty file.

# Prefix first rule with cmi-target.
if [[ -n ${prefix_first_rule} && -n ${cmitarget} ]]; then
	echo -n "${cmitarget} " >> "${dep}"
fi

# Read in existing dep-file:
# If required escape dependencies for secondary expansion.
# Comment lines and escaped backslashes at the end of the line are not considered!
cont=
declare -i pos_colon no_backslash length i
while read -r; do
	if [[ -z ${secondary_exp} ]]; then
		echo "${REPLY}" >> "${dep}"
	else
		if [[ -z ${cont} ]]; then # Start of a new logical line.
			pos_colon=-1
		fi
		length=${#REPLY}
		if (( length == 0 )); then # Passing empty lines.
			echo >> "${dep}"
			cont=
		else
			if (( pos_colon == -1 )); then # We are still in the target section.
				no_backslash=0
				i=0
				while (( i < length )) && (( pos_colon == -1 )); do # Searching for an unescaped colon.
					c="${REPLY:i:1}"
					if [[ $c == "\\" ]]; then
						no_backslash+=1
					elif [[ $c == ":" ]]; then
						if (( ( no_backslash % 2 ) == 0 )); then
							pos_colon=$i
						fi
						no_backslash=0
					else
						no_backslash=0
					fi
					(( i++ )) || :
				done
				if (( pos_colon == -1 )); then
					echo "${REPLY}" >> "${dep}"
				else
					targets="${REPLY:0:pos_colon}"
					prerequisites="${REPLY:pos_colon+1}"
					echo "${targets}:${prerequisites//\$/\$\$}" >> "${dep}"
				fi
			else # We are in the prerequisites section.
				echo "${REPLY//\$/\$\$}" >> "${dep}"
			fi
			if [[ ${REPLY: -1} == "\\" ]]; then # Note the space after colon.
				cont=1
			else
				cont=
			fi
		fi
	fi
done < "${deptemp}"
[[ -n $REPLY ]] && errexit "Missing trailing newline" 1


# Appending module deps to depfile.
if [[ -n ${add_module_dep_rule} ]]; then
	if [[ -n ${requires} ]]; then
		{
			escape_for_rule "${obj}" 1
			if [[ -n ${cmitarget} ]]; then
				echo -n "${cmitarget} ${result} "
			else
				echo -n "${result} "
			fi
			echo -n ": "
			for module in ${requires}; do
				module_subst="${module//:/"-"}" # Make prohibits colons in variable names.
				preq="${prereq_templ//mod/"${module_subst}"} "
				if [[ -n ${secondary_exp} ]]; then
					preq="${preq//\$/\$\$}"
				fi
				echo -n "${preq}"
			done
			echo
		} >> "${dep}"
	fi
fi

# Prepare mdbfile.
if [[ -z ${one_output_file} ]]; then
	rm -f "${mdbfile}"
fi

# Dump provided module to mdbfile:
escape_for_assign "${src}"
src_escaped="${result}"
escape_for_assign "${obj}"
obj_escaped="${result}"
if [[ -z ${provides} ]]; then
	provides='-'
fi
{
	if [[ -z ${append_module_deps} ]]; then
		echo "CXX_SRC_OBJ_MOD_IF_LIST += ${src_escaped};${obj_escaped};${provides};${is_if}"
	else
		echo -n "CXX_SRC_OBJ_MOD_IF_REQ_LIST += ${src_escaped};${obj_escaped};${provides};${is_if}"
		# requires is the list of module names, thus no further special character are expected.
		for mod in ${requires}; do
			# Dollar symbols are already doubled.
			echo -n ";${mod//:/"-"}"
		done
		echo
	fi
}  >> "${mdbfile}"

exit 0
