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
usage="usage: ${command} input depfile mdbfile object source [cmitarget]"

myhelp() {
	cat <<-EOF

	${usage}

	    Parameters:
	        input     : Input        - file with dependency information according to P1689
	        depfile   : Input/Output - make dependency file to be extended with module dependency information
	        mdbfile   : Output       - module information in make format
	        object    : The primary_output (object) file of the TU
	        source    : The source file name
	        cmitarget : If present, the first line is preceded with this target. The string $(mod) is substituted
	                    with the provided module name. The string $(src) is substituted with the source name. Escape
	                    character are applied.

	1) Detect module dependencies for a translation unit in 'input' and append the
	module prerequisites in makefile format to 'depfile'. Modules are represented by a variable
	like CXX_MOD_modulname_CMI.
	The CMI-file-name for a given module must be provided by the make-script.
	The module dependency rule for a translation unit that imports modules has
	the form:
	        object : \$(CXX_MOD_require1_CMI) \$(CXX_MOD_require2_CMI)...
	If the translation unit provides a module:
	        object \$(call cmi_mapper,module,source) : \$(CXX_MOD_require1_CMI) \$(CXX_MOD_require2_CMI)...
	Dollar symbols in names are replaced by two dollar symbols.
	In variables CXX_MOD_require1_CMI a colon in the required module name (module partitions) is replaced
	by a dash and dollar symbols are replaced by two dollar symbols.

	2) Dump the module dependency database in makefile format from all input files to 'mdbfile'
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
elif [[ $# -ne 5 && $# -ne 6 ]]; then
	errexit "5 or 6 parameters required $# given!" 2
fi

readonly inp="$1" dep="$2" mbf="$3" obj="$4" src="$5"
cmitarget=
if [[ $# -eq 6 ]]; then
	cmitarget="$6"
fi
readonly cmitarget

[[ -z "${inp}" || -z "${dep}" || -z "${mbf}" || -z "${obj}" || -z "${src}" ]] \
	&& errexit "None of the parameters must be empty!" 2
[[ -r "${inp}" ]] || errexit "Input file ${inp} is not readable!" 1
[[ -r "${dep}" ]] || errexit "Input file ${dep} is not readable!" 1

# check primary output
my_unit=$(jq -cj ".rules[] | select(.[\"primary-output\"] == \"${obj}\")" "${inp}")
[[ -z "${my_unit}" ]] && errexit "No primary-output : ${obj} found" 1

requires=$(echo "${my_unit}" | jq -r 'if .requires then .requires[].["logical-name"] else empty end')

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

src_escaped="${src//\$/\$\$}"
obj_escaped="${obj//\$/\$\$}"

# precede the target list if required
if [[ -n ${cmitarget} && -n ${provides} ]]; then
	readonly deptemp="${dep}~"
	mv "${dep}" "${deptemp}"

	# assume $(mod) and $(src) are substituted in context of a function thus # and : are not special
	temp1="${cmitarget//\$(mod)/${provides}}"
	temp2="${temp1//\$(src)/${src_escaped}}"
	echo -n "${temp2} " > "${dep}"
	while read -r; do
		echo "${REPLY}" >> "${dep}"
	done < "${deptemp}"
fi

# append module deps to depfile
if [[ -n ${requires} ]]; then
	{
		echo -n "${obj_escaped//#/\\#}" # in rule context hash mark must be quoted
		if [[ -n ${provides} ]]; then
			echo -n " \$(call cmi_mapper,${provides},${src_escaped})"
		fi
		echo -n " :"
		for module in ${requires}; do
			module_subst="${module//:/"-"}" # Make prohibits colons in variable names.
			echo -n " \$(CXX_MOD_${module_subst//\$/\$\$}_CMI)"
		done
		echo
	} >> "${dep}"
fi

# dump provided module to mdbfile
{
	if [[ -z ${provides} ]]; then
		echo "CXX_SRC_MOD_IF_LIST += ${src_escaped//#/\\#};-;0" # in assignment hash mark must be quoted
	else
		echo "CXX_SRC_MOD_IF_LIST += ${src_escaped//#/\\#};${provides};${is_if}" # provides should not contain #
	fi
} > "${mbf}"

exit 0
