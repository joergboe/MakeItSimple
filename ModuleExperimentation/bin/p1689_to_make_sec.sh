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
usage="usage: ${command} input depfile object source
       ${command} -h|--help"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input - file with structured dependency information according to P1689
	        depfile   : Input/output - make dependency file to be extended with module dependency information
	        object    : The primary_output (object) file name of the translation unit
	        source    : The source file name of the translation unit

	1) Read in the existing depfile and re-write prerequisites with escaped dollar symbols for secondary expansion.

	2) Detect module dependencies for a translation unit in 'input' and append the
	module prerequisites in makefile format to 'depfile'. Modules are represented by a variable
	like CXX_MOD_modulname_CMI.
	The CMI-file-name for a given module must be provided by the make-script.
	The module dependency rule for a translation unit that imports modules has
	the form:
	        object : \$\$(CXX_MOD_require1_CMI) \$\$(CXX_MOD_require2_CMI)...
	If the translation unit provides a module:
	        object \$(call cmi_mapper,module,source) : \$\$(CXX_MOD_require1_CMI) \$\$(CXX_MOD_require2_CMI)...
	Dollar symbols in names are replaced by four dollar symbols.
	In variables CXX_MOD_require1_CMI a colon in the required module name (module partitions) is replaced
	by a dash.

	3) Dump the module dependency database in makefile format from all input files to 'mdbfile'
	For each translation unit that provides a module, a triple of the following
	form is emitted:
	        CXX_SRC_MOD_IF_LIST += source;provides;is_interface(0/1)
	For a non module translation unit, the following triple is emitted:
	        CXX_SRC_MOD_IF_LIST += source;-;0
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

if [[  $# -ge 1 && ( $1 == '-h' || $1 == '--help' ) ]]; then
	myhelp
	exit 0
elif [[ $# -ne 4 ]]; then
	errexit "ERROR: 4 parameters required $# given!" 2
fi

readonly inp="$1" dep="$2" obj="$3" src="$4"

[[ -z "${inp}" || -z "${src}" || -z "${obj}" || -z "${dep}" ]] \
	&& errexit "None of the parameters must be empty!" 2
[ -r "${inp}" ] || errexit "Input file ${inp} is not readable!" 1

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

requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')

# Read existing dep-file and escape dependencies for secondary expansion
# Comment lines and escaped backslashes at the end of the line are not considered
readonly deptemp="${dep}~"
mv "${dep}" "${deptemp}"
touch "${dep}" # ensure at least an empty file

cont=
declare -i pos_colon no_backslash length x
while read -r; do
	if [[ -z ${cont} ]]; then
		pos_colon=-1
	fi
	length=${#REPLY}
	if (( length == 0 )); then
		echo >> "${dep}"
		cont=
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
				echo "${REPLY}" >> "${dep}"
			else
				targets="${REPLY:0:pos_colon}"
				prerequisites="${REPLY:pos_colon+1}"
				echo "${targets}:${prerequisites//\$/\$\$}" >> "${dep}"
			fi
		else
			echo "${REPLY//\$/\$\$}" >> "${dep}"
		fi
		if [[ ${REPLY: -1} == "\\" ]]; then # Note the space after colon
			cont=1
		else
			cont=
		fi
	fi
done < "${deptemp}"

[[ -n $REPLY ]] && errexit "Missing trailing newline" 1
rm "${deptemp}"

is_if=0
if [[ -n ${provides} ]]; then
	if [[ ${is_interface} = 'null' ]]; then
		is_if=1 # is-interface is optional and default is true
	elif [[ ${is_interface} = 'true' ]]; then
		is_if=1
	fi
	provides=${provides//\$/\$\$} # escape $ in make style
fi

# Append variables for required module interfaces
src_escaped="${src//\$/\$\$}"
obj_escaped="${obj//\$/\$\$}"
if [[ -n ${requires} ]]; then
	{
		echo -n "${obj_escaped//#/\\#}" # in rule context hash mark must be quoted
		if [[ -n ${provides} ]]; then
			echo -n " \$(call cmi_mapper,${provides},${src_escaped})"
		fi
		echo -n " :"
		for module in ${requires}; do
			module_subst="${module//:/"-"}" # Make prohibits colons in variable names.
			echo -n " \$\$(CXX_MOD_${module_subst//\$/\$\$\$\$}_CMI)" # secondary expansion is enabled
		done
		echo
	} >> "${dep}"
fi

# append source;module;is_interface triples
{
	if [[ -z ${provides} ]]; then
		echo "CXX_SRC_MOD_IF_LIST += ${src_escaped//#/\\#};-;0" # in assignment hash mark must be quoted
	else
		echo "CXX_SRC_MOD_IF_LIST += ${src_escaped//#/\\#};${provides};${is_if}" # provides should not contain #
	fi
} >> "${dep}"

exit 0
