# *** Shell Utilities ***

# Print a red error message to stderr and exit. If the return code is 2, then $4 follows the error message.
# Parameters:
#    $1 - message
#    $2 - return code
#    $3 - usage
error() {
	local red=
	local end=
	if [ -t 2 ]; then
		red="\033[31m"
		end="\033[0m"
	fi
	echo -e "${red}ERROR: ${0##*/} (${BASH_LINENO[0]}) : $1${end}" >&2
	[ "$2" == 2 ] && echo -e "\n$3\n" >&2
	exit "$2"
}

# Print a yellow warning message to stderr and proceed.
# Parameter:
#    $1 - message
warning() {
	local yel=
	local end=
	if [ -t 2 ]; then
		yel="\033[33m"
		end="\033[0m"
	fi
	echo -e "${yel}WARNING: $1${end}" >&2
}

# Read existing dep-file and get the prerequisites.
# These files are generated from gcc.
# Currently gcc inserts a space and a backslash to continue a long line. So we do not expect escaped newline
# directly after a word.
# We also do not expect comments in such gcc generated files.
# Currently gcc does not escape colons in file names so we do not care about escaped colons here.
# Empty lines and lines are silently ignored.
# Lines without colon are reported and ignored.
#
# Parameter:
#    $1 - The filename to scan.
# Output:
#    get_prerequisites_result - All prerequisites of the first rule found (space separated).
declare get_prerequisites_result
get_prerequisites() {
	get_prerequisites_result=
	local logical_line=
	while read -r; do
		[ -z "${verbose}" ] || echo "REPLY='${REPLY}'"
		if [[ ${REPLY: -1} == "\\" ]]; then # Note the space after colon.
			logical_line+="${REPLY:0: -1} " # Make adds at least one space in a continuation line, thus we do so.
		else
			logical_line+="${REPLY}"
			[ -z "${verbose}" ] || echo "logical_line='${logical_line}'"
			if [ -z "${logical_line}" ]; then
				continue
			elif [[ ${logical_line} =~ (.*):(.*) ]]; then
				get_prerequisites_result="${BASH_REMATCH[2]}"
				break
			else
				warning "Ignored line '${logical_line}'"
			fi
			logical_line=
		fi
	done < "$1"
	[ -z "${verbose}" ] || { echo "get_prerequisites_result='${get_prerequisites_result}'"; echo; }
}

# Scan prerequisites using the the GNU make quoting scheme for white space and special characters.
# A special character preceded by 2N+1 backslashes represents N backslashes followed by the literal character;
# a special character preceded by 2N backslashes represents N backslashes at the end of a file name.
# Special character in context of a rule are space, tab, hashmark, colon.
#
# Parameters:
#    $1 - The quoted prerequisites list.
#    $2 - If set the function stops after the first prerequisite.
# Output:
#    scan_prerequisites_result -The indexed array with the unquoted prerequisites.
declare -a scan_prerequisites_result
scan_prerequisites() {
	unset "scan_prerequisites_result[*]" # Clear the output list.
	local prereq=
	local -i slashes=0
	local c=
	local -i i
	for ((i=0;i<${#1};i++)); do
		c="${1:${i}:1}"
		case "${c}" in
			\\)
				((slashes++)) || : ;;
			\ |\	|\#|:)
				if (( slashes%2 )); then
					# Odd number of slashes means this character is escaped. Add (x-1)/2 backslashes and the character.
					((slashes--)) || : # Guard the arithmetical expression.
					slashes=$((slashes>>1))
					while ((slashes--)); do prereq+=\\; done
					slashes=0
					prereq+="${c}"
				else
					# Even number of slashes means this character is a delimiter means the end of a word.
					# Add (x)/2 backslashes and skip the character.
					slashes=$((slashes>>1))
					while ((slashes--)); do prereq+=\\; done
					slashes=0
					if [[ -n "${prereq}" ]]; then
						scan_prerequisites_result+=( "${prereq//\$\$/\$}" )
						prereq=
						if [[ -n $2 ]]; then # Stops after the first prerequisite.
							break
						fi
					fi
				fi ;;
			*)
				# Before non special characters the slashes are taken as is.
				while ((slashes--)); do prereq+="\\"; done
				slashes=0
				prereq+="${c}";;
		esac
	done
	if ((slashes)); then
		# The line has no space after the last word and the newline follows directly after trailing slash.
		# This means 2N backslashes.
		if (( slashes%2 )); then
			error "Odd number of backslashes at line end in line $1" 1
		fi
		while ((slashes--)); do prereq+=\\; done
	fi
	if  [[ -n "${prereq}" ]]; then
		# The line has no space after the last word and the newline follows directly.
		scan_prerequisites_result+=( "${prereq//\$\$/\$}" )
	fi
	if [ -n "${verbose}" ]; then
		echo -n 'scan_prerequisites_result='
		for ((i=0;i<${#scan_prerequisites_result[*]};i++)); do
			echo -n "'${scan_prerequisites_result[i]}'" " "
		done
		echo
	fi
}

# Escape the rhs of an assignment according to the make rules.
# Dollar signs are doubled, and hash-mark is escaped by one backslash.
# Backslashes before hash-mark are doubled.
# Parameter:
#    $1 - input string
# Output:
#    escape_for_assign_result - output string
declare  escape_for_assign_result
escape_for_assign() {
	escape_for_assign_result=
	local -i i
	local c
	local -i slashes=0
	for ((i=0;i<${#1};i++)); do
		c="${1:${i}:1}"
		case "${c}" in
			\\)
				((slashes++)) || : ;;
			\$)
				escape_for_assign_result+="${c}"
				slashes=0;;
			\#)
				((slashes++)) || : # 2*slashes + 1 must precede a special character.
				while ((slashes--)); do escape_for_assign_result+=\\; done;&
				# FALLTHROUGH
			*)
				slashes=0;;
		esac
		escape_for_assign_result+="${c}"
	done
}

# Escape a string to be used as target or prerequisite according to make rules.
# Dollar signs are doubled.
# Special characters (space, tab, hash-mark and colon) are escaped by one backslash.
# Backslashes before special characters are doubled.
# Parameters:
#    $1 - input string
#    $2 - If this parameter is non empty, we assume that a space follows the input.
#         In this case the final backslashes are doubled. If the input is the final element
#         the final backslashes are not doubled.
# Output:
#    escape_for_rule_result - output string
declare escape_for_rule_result
escape_for_rule() {
	escape_for_rule_result=
	local -i i
	local c
	local -i slashes=0
	for ((i=0;i<${#1};i++)); do
		c="${1:${i}:1}"
		case "${c}" in
			\\)
				((slashes++)) || : ;;
			\$)
				escape_for_rule_result+="${c}"
				slashes=0;;
			\ |\	|\#|:)
				((slashes++)) || : # 2*slashes + 1 must precede a special character.
				while ((slashes--)); do escape_for_rule_result+=\\; done;&
				# FALLTHROUGH
			*)
				slashes=0;;
		esac
		escape_for_rule_result+="${c}"
	done
	if [ -n "$2" ]; then
		# If space follows we must double the number of backslashes.
		while ((slashes--)); do escape_for_rule_result+=\\; done
	fi
}

# Read a mapper file according to the gcc rules and output the mapper_root
# and the source array and the CMI array. The coresponding entries of source and
# CMI array belong to the same module.
# Parameters:
#   $1 - mapper file
# Output:
#    read_mmap_root - The mapper root from the first line of mapper file. Root is empty
#                     if no root statement was found.
declare read_mmap_root
declare -a read_mmap_src
declare -a read_mmap_cmi
read_mmap() {
	read_mmap_root=
	read_mmap_src=()
	read_mmap_cmi=()

	local -a arr
	local src cmi
	local first_line=1
	while read -r -a arr; do

		if [[ -n ${first_line} ]]; then
			first_line=
			if [[ ${#arr[*]} -gt 0 && ${arr[0]} = \$root ]]; then
				if [[ ${#arr[*]} -gt 1 ]]; then
					read_mmap_root="${arr[1]}"
					if [[ "${read_mmap_root}" = '.' ]]; then
						read_mmap_root=
					fi
				fi
				[ -z "${verbose}" ] || echo "Using cache root '${read_mmap_root}'"
				continue
			fi
			[ -z "${verbose}" ] || echo "No cache root found."
		fi

		[[ ${#arr[*]} -ne 2 ]] && error "Ignored line in mapfile '${arr[*]}'"
		src="${arr[0]/#.\//}"
		if [ -n "${read_mmap_root}" ]; then
			cmi="${read_mmap_root}/${arr[1]}"
		else
			cmi="${arr[1]}"
		fi
		read_mmap_src+=( "${src}" )
		read_mmap_cmi+=( "${cmi}" )
		[ -z "${verbose}" ] || { echo "${src} ${cmi}"; }

	done < "$1"
	if [ ${#arr[*]} != 0 ]; then
		warning "Missing final nl in mapper file $1. Line ignored!"
	fi
}
