#!/usr/bin/env bash

# Some recommended security settings:
unset -f unalias
\unalias -a
unset -f command
IFS=$' \t\n'
#set -o posix;
set -f  # Disable path name expansion.
set -o errexit; set -o errtrace; set -o nounset; set -o pipefail

usage="usage: ${0##*/} [OPTION]... [--] mapper-in depfile-out project-dir build-dir-sys build-dir-user
	                                    depfile-suffix cache-dir cmi-suffix [depfile-in [depfile-in [...]]]"

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
	        cache-dir     : The CMI-cache directory.
	        cmi-suffix    : Filename suffix for CMI-files.
	        depfile-in    : The input dependency information of one unit. The unit name

	    Options:
	        -h        : Help
	        -v        : Verbose
	        -r        : Root - use the \$root statement in the first line in 'mapper-out'

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

	3) The CMI file name is constructed from the module name. Dot characters in the module name are
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
	    unit name      : The unit name is the name of defile-in with depfile suffix removed.
	    source name    : The source file name from the first prerequisite in depfile
	    logical module : The logical module name. The source name if the source path is absolute. If the source path is
	                     relative and does not begin with a dot, a ‘./’ directory is prepended.
	    cmi            : The CMI file name: <cache>/<logical module>.<ext>. Internal ‘..’ or '.' components are
	                     translated to ‘,,’ or '.' in logical module.

	    The output is escaped according to the make rules.
	    Dollar signs are doubled, and hash-mark is escaped by one backslash.
	    Backslashes before hash-mark are doubled.

	5) The scrip builds the mapping file mapper-out.

	  With option -r:
	    \$root cache-dir
	    src1 cmi1_wo_cache_dir
	    src2 cmi2_wo_cache_dir

	  Without option -r:
	    src1 cmi1
	    src2 cmi2

	EOF
}

bin="${0%/*}"
source -p "${bin}" header-common-definitions.sh

verbose=
root_line=
while getopts 'hvr' arg; do
	case ${arg} in
		h) myhelp; exit 0;;
		v) verbose=1;;
		r) root_line=1;;
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
	echo "root_line=${root_line}"
	for x in mapper_out depfile_out project_dir build_dir_sys build_dir_user depfile_suffix cache_dir cmi_suffix; do
		echo "${x}=${!x}"
	done
	echo
fi
