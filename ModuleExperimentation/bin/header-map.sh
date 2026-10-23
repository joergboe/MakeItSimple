#!/usr/bin/env bash

# some recommended security settings
unset -f unalias
\unalias -a
unset -f command
#some setup to be save
IFS=$' \t\n'
#set -o posix;
set -f  # disable pathname expansion
set -o errexit; set -o errtrace; set -o nounset; set -o pipefail

command=${0##*/}
usage="usage: ${command} [-h|-v].. [--] mapper-out depfile-out project-dir build-dir-sys build-dir-user depfile-suffix cache-dir cmi-suffix [depfile-in [depfile-in [...]]]"

myhelp() {
	cat <<-EOF

	Build the header mapper file and make database.

	${usage}

	    Parameters:
	        mapper-out    : A file with the system header database <source> <cmi>
	        depfile-out   : The input file with header dependencies in make format
	        project-dir   : Absolute path of current directory from make (without trailing slash!).
	        build-dir-sys : Prefix path for system header unit depfiles.
	        build-dir-user: Prefix path for user header unit depfiles.
	        depfile-suffix: Filename suffix for depfiles.
	        cache-dir     : The cmi-cache directory.
	        cmi-suffix    : Filename suffix for cmi-files.
	        depfile-in    : The input dependency information of one unit. The unit name

	    Options:
	        -h        : Help
	        -v        : Verbose

	1) This script looks in depfile-in for the first prerequisite in the first rule which is the
	source file name.

	2) The module name (logical name) is constructed from the source file name:
	    Absolute source file:
	        mod=/usr/include/c++/16/iostream
	        mod=/home/src/sample/../module.h
	    Relative source file:
	        mod=./header2.h
	        mod=./incl/header2.h
	        mod=./incl/../header2.h
	        mod=./../header2.h

	3) The cmi file name is constructed from the module name. Dot characters in the module name are
	replaced by commas.
	
	    Absolute source file:
	        cmi=<cache-dir>/.<module-name-repl><cmi-suffix>
	        src=/usr/include/c++/16/iostream    cmi=gcm.cache/./usr/include/c++/16/iostream.gcm
	        src=/home/src/sample/../module.h    cmi=gcm.cache/./home/src/sample/,,/module.h.gcm
	    Relative source file:
	        cmi=<cache-dir>/<module-name-repl><cmi-suffix>
	        src=header2.h          cmi=gcm.cache/,/header2.h.gcm
	        src=incl/../header2.h  cmi=gcm.cache/,/incl/,,/header2.h.gcm
	        src=../header2.h       cmi=gcm.cache/,/,,/header2.h.gcm

	4) Output the variable CXX_KIND_UNIT_SRC_MOD_CMI_LIST

	The output in one line of the form:

	        CXX_KIND_UNIT_SRC_MOD_CMI_LIST += <kind>;<unit name>;<source name>;<logical module>;<cmi name>

	    kind           : The kind of the unit: system or user.
	    unit name      : The unit name from command line
	    source name    : The source file name from the first prerequisite in depfile
	    logical module : The logical module name. The source name if the source path is absolute. If the source path is
	                     relative and does not begin with a dot, a ‘./’ directory is prepended.
	    cmi            : The CMI file name: <cache>/<logical module>.<ext>. Internal ‘..’ or '.' components are
	                     translated to ‘,,’ or '.' in logical module.

	5) The scrip builds the mapping file mapper-out.

	    \$root cache-dir
	    src1 cmi1
	    src2 cmi2
	
	Dollar symbols in names are replaced by two dollar symbols.

	EOF
}

bin="${0%/*}"
source -p "${bin}" header-common-definitions.sh

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

if [[ $# -lt 8 ]]; then
	errexit "At least 8 position parameters required $# given!" 2
fi

readonly mapper_out="$1" depfile_out="$2" project_dir="$3"
build_dir_sys="$4" build_dir_user="$5"
readonly depfile_suffix="$6"
cache_dir="$7"
readonly cmi_suffix="$8"

shift 8

if [ -n "${verbose}" ]; then
	for x in mapper_out depfile_out project_dir build_dir_sys build_dir_user depfile_suffix cache_dir cmi_suffix; do
		echo "${x}=${!x}"
	done
	echo
fi

for x in mapper_out depfile_out depfile_suffix cmi_suffix build_dir_sys build_dir_user; do
	if [[ -z ${!x} ]]; then
		errexit "Parameter $x must not be empty!" 2
	fi
done

for x in project_dir build_dir_sys build_dir_user cache_dir; do
	if [[ ${!x} = */ ]]; then
		errexit "${x} must not end with /!" 2
	fi
done

if [[ ${project_dir} != /* ]]; then
	errexit "project_dir '${project_dir}' must be an absolute path"
fi

if [[ ${cache_dir} = '.' ]]; then
	cache_dir=
fi
readonly cache_dir

for x in build_dir_sys build_dir_user; do
	if [[ ${!x} = .* ]]; then
		errexit "${x} must not contain the dot directory!" 2
	fi
done

build_dir_sys_p="${build_dir_sys}/"
build_dir_user_p="${build_dir_user}/"
cache_dir_p=
[ -n "${cache_dir}" ] && cache_dir_p="${cache_dir}/"

readonly build_dir_sys_p build_dir_user_p cache_dir_p
unset build_dir_sys build_dir_user

if [ -n "${verbose}" ]; then
	echo "build_dir_sys_p='${build_dir_sys_p}'"
	echo "build_dir_user_p='${build_dir_user_p}'"
	echo "cache_dir_p='${cache_dir_p}'"
	echo
fi

if [ "${build_dir_sys_p}" = "${build_dir_user_p}" ]; then
	errexit "build_dir_sys and build_dir_user must denote different directories!" 2
fi

# Prepare the output file. Ensure at least an empty output file
echo "# This is a generated file. Do not edit!" > "${depfile_out}"

# The database over all header files to translate.
# Key is the source/header file; Value is the cmi file to generate.
declare -A src_cmi=() # The database [src]->cmi

mapper="\$root ${cache_dir}"$'\n'

for ((findex=1; findex<=$#; findex++)); do
	inp="${!findex}"
	[ -z "${verbose}" ] || echo "scanning #${findex} '${inp}'"
	[[ -r "${inp}" ]] || errexit "file '${inp} is not readable!" 2

	# Reading the complete first rule.
	get_prerequisites "${inp}"

	# Get the first word from prerequisites.
	scan_prerequisites "${prerequisites}" stop

	src=
	if [[ ${#prereq_list[*]} -ne 1 ]]; then
		error "No valid rule found in '${inp}'!"
		break
	else
		src="${prereq_list[0]}"
	fi
	[ -z "${verbose}" ] || echo "src='${src}'"

	if [[ -z ${src} ]]; then
		error "No valid rule found in '${inp}'!"
		break
	fi

	if [[ ${src} == /* || ${src} == .* ]]; then
		logname="${src}"
	else
		logname="./${src}"
	fi
	[ -z "${verbose}" ] || echo "logname='${logname}'"
	# replace /../ with /,,/ in cmi file component
	temp="${logname//\/..\//\/,,\/}"
	[ -z "${verbose}" ] || echo "temp='${temp}'"
	# replace /./ with /,/ in cmi file component
	temp2="${temp//\/.\//\/,\/}"
	[ -z "${verbose}" ] || echo "temp2='${temp2}'"
	# replace ./ with ,/ at beginning
	temp3="${temp2/#.\//,\/}"
	[ -z "${verbose}" ] || echo "temp3='${temp3}'"
	# complete cmi name
	if [[ ${temp3} == /* ]]; then
		cmi="${cache_dir_p}.${temp3}${cmi_suffix}" # emulate the default gcc mapper
	else
		cmi="${cache_dir_p}${temp3}${cmi_suffix}"
	fi
	[ -z "${verbose}" ] || echo "cmi='${cmi}'"

	src_cmi[$src]="${cmi}"
	temp4="${cmi#"${cache_dir}/"}"
	mapper+="${logname//\$\$/\$} ${temp4//\$\$/\$}"$'\n'

	# Get the unit name and kind from input parameters.
	if [[ ${inp} = ${build_dir_sys_p}?* ]]; then
		kind=system
		tmp="${inp#"${build_dir_sys_p}"}"
	elif [[ ${inp} = ${build_dir_user_p}?* ]]; then
		kind=user
		tmp="${inp#"${build_dir_user_p}"}"
	else
		errexit "Input file '${inp}' must be either in system build dir '${build_dir_sys_p}' or user build dir '${build_dir_user_p}'!" 2
	fi
	unit="${tmp%"${depfile_suffix}"}"

	escape_for_assign "${kind};${unit};${src};${logname};${cmi}"

	# Write variable CXX_UNIT_SRC_MOD_CMI_KIND_LIST
	the_var="CXX_KIND_UNIT_SRC_MOD_CMI_LIST += ${result}"
	echo "${the_var}" >> "${depfile_out}"
done
[ -z "${verbose}" ] || declare -p src_cmi

# Write the mapper file.
echo -n "${mapper}" > "${mapper_out}"

[ -z "${verbose}" ] || echo "Done ${depfile_out}"
exit 0
