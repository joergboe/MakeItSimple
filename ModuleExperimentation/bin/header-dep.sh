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
usage="usage: ${command} [-h|-v].. [--] mapper-in depfile-in depfile-in project-dir depfile-out"

myhelp() {
	cat <<-EOF

	Build the the module dependencies for header units.

	${usage}

	    Parameters:
	        mapper-in    : A file with the system header database <source> <cmi>
	        depfile-in    : The input dependency information of one unit. The unit name
	        project-dir   : Absolute path of current directory from make (without trailing slash!).
	        depfile-out   : The input file with header dependencies in make format

	    Options:
	        -h        : Help
	        -v        : Verbose

	1) The scrip reads the mapping file mapper-in.

	    \$root cache-dir
	    src1 cmi1
	    src2 cmi2
	
	6) The script scans the (header) dependencies of a header unit (the first rule). If a dependency exists in the
	mapping  database, a rule with the dependend cmi file is added:

	    <my-cmi> : <dpendency-cmi1> <dpendency-cmi2>

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

if [[ $# -lt 4 ]]; then
	errexit "At least 4 position parameters required $# given!" 2
fi

readonly mapper_in="$1" depfile_in="$2" project_dir="$3" depfile_out="$4"

shift 4

if [ -n "${verbose}" ]; then
	for x in mapper_in depfile_in project_dir depfile_out; do
		echo "${x}=${!x}"
	done
	echo
fi

for x in mapper_in depfile_in project_dir depfile_out; do
	if [[ -z ${!x} ]]; then
		errexit "Parameter $x must not be empty!" 2
	fi
done

if [[ ${project_dir} = */ ]]; then
		errexit "${project_dir} must not end with /!" 2
	fi

if [[ ${project_dir} != /* ]]; then
	errexit "project_dir '${project_dir}' must be an absolute path"
fi

# The database over all header files to translate.
# Key is the source/header file; Value is the cmi file to generate.
declare -A src_cmi=() # The database [src]->cmi

[[ -r "${mapper_in}" ]] || errexit "file '${mapper_in}' is not readable!" 2
[ -z "${verbose}" ] || echo "Scanning mapfile '${mapper_in}'"

first_line=1
root=
while read -r -a arr; do
	if [[ -n ${first_line} ]]; then
		first_line=
		[[ ${#arr[*]} -lt 1 || ${arr[0]} != '$root' ]] && errexit "No root found in mapefile!" 1
		if [[ ${#arr[*]} -gt 1 ]]; then
			root="${arr[1]}"
		fi
		if [[ "${root}" = '.' ]]; then
			root=
		fi
		[ -z "${verbose}" ] || echo "Using cache root '${root}'"
	else
		[[ ${#arr[*]} -ne 2 ]] && error "Ignored line in mapfile '${arr[*]}'"
		src="${arr[0]/#.\//}"
		src_cmi+=(["${src}"]="${root}/${arr[1]}")
	fi
done < "${mapper_in}"
[ -z "${verbose}" ] || { declare -p src_cmi; echo; }

# Scans the (header) dependencies of a header unit (the first rule). If a dependency exists in the
# mapping database, a rule with the dependend cmi file is added.

declare -a prerequisites_found=()

[ -z "${verbose}" ] || echo "scanning2 '${depfile_in}'"

# Reading the complete first rule.
get_prerequisites "${depfile_in}"

# Get the list of all from prerequisites. Using the the GNU make quoting scheme for white space.
scan_prerequisites "${prerequisites}" ''

# If any of the header files in prereq_list is key in the list src_cmi a dependency rule is generated.
# <my-cmi> : <dpendency-cmi1> <dpendency-cmi2>

target=
unset "prerequisites_found[*]"

for ((i=0;i<${#prereq_list[*]};i++)); do
	preq="${prereq_list[i]}"
	[ -z "${verbose}" ] || echo "Checking preq #$i '${preq}'"
	set +o nounset
	temp="${src_cmi["${preq}"]}"
	set -o nounset
	if [[ i -eq 0 ]]; then
		if [ -z "${temp}" ]; then
			errexit "Source #1 '${preq}' not found in src_cmi mapper!" 1
		fi
		target="${temp}"
	else
		if [[ -n ${temp} ]]; then
			# The header preq was literally found in database.
			rule+=" ${temp}"
			prerequisites_found+=( "${temp}" )
		else
			if [[ ${preq} == /* ]]; then # preq is absolute - check whether we have the relative pathname in db
				relative_path="$(realpath --relative-to="${project_dir}" "${preq}")"
				[ -z "${verbose}" ] || echo "Checking relative_path='${relative_path}'"
				set +o nounset
				temp="${src_cmi["${relative_path}"]}"
				set -o nounset
				if [[ -n ${temp} ]]; then
					prerequisites_found+=( "${temp}" )
				fi
			else # preq is relative - check whether we have the absolute pathname in cache
				abs_path="${project_dir}/${preq}"
				[ -z "${verbose}" ] || echo "Checking abs_path='${abs_path}'"
				set +o nounset
				temp="${src_cmi["${abs_path}"]}"
				set -o nounset
				if [[ -n ${temp} ]]; then
					prerequisites_found+=( "${temp}" )
				fi
			fi
		fi
	fi
done

# Prepare the output file. Ensure at least an empty output file
echo "# This is a generated file. Do not edit!" > "${depfile_out}"

escape_for_rule "${target}" 1
rule="${result} :"
p_limit=$((${#prerequisites_found[*]} - 1))
for ((i=0;i<=p_limit;i++)); do
	space_follows=
	if [[ i -lt p_limit ]]; then
		space_follows=1
	fi
	escape_for_rule "${prerequisites_found[i]}" "${space_follows}"
	rule+=" ${result}"
done

[ -z "${verbose}" ] || echo "rule '${rule}'"

if [[ p_limit -ge 0 ]]; then
	echo "${rule}" >> "${depfile_out}"
	[ -z "${verbose}" ] || echo "Rule written to '${depfile_out}'."
else
	[ -z "${verbose}" ] || echo "No rule output"
fi

[ -z "${verbose}" ] || echo "Done ${depfile_out}"
exit 0
