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

# Reading the complete first rule and get the prerequisites.
# Read existing dep-file and get the first prerequisite. These files are generated from gcc.
# Currently gcc inserts a space and a backslash to continue a long line. So we do not expect escaped newline
# directly after a word.
# We also do not expect comments in such gcc generated files.
# Currently gcc does not escape colons in file names so we do not care about escaped colons here.
# Empty lines and lines are silently ignored.
# Lines without colon are reported and ignored.
#
# Parameters: $1 - The filename to scan.
# Output: prerequisites - All prerequisites of the first rule found.
prerequisites=
get_prerequisites() {
	prerequisites=
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
				prerequisites="${BASH_REMATCH[2]}"
				break
			else
				error "Ignored line '${logical_line}'"
			fi
			logical_line=
		fi
	done < "$1"
	[ -z "${verbose}" ] || { echo "prerequisites='${prerequisites}'"; echo; }
}

# Scan prerequisites using the the GNU make quoting scheme for white space and special characters.
# A special character preceded by 2N+1 backslashes represents N backslashes followed by the literal character;
# a special character preceded by 2N backslashes represents N backslashes at the end of a file name.
# Special character in context of a rule are space, tab, hashmark, colon.
#
# Parameters: $1 - The quoted prerequisites list.
#             $2 - If set the function stops after the first prerequisite.
# Output: prereq_list -The indexed array with the unquoted prerequisites.
declare -a prereq_list=()
scan_prerequisites() {
	unset "prereq_list[*]" # Clear the output list.
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
						prereq_list+=( "${prereq//\$\$/\$}" )
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
			errexit "Odd number of backslashes at line end in line $1" 1
		fi
		while ((slashes--)); do prereq+=\\; done
	fi
	if  [[ -n "${prereq}" ]]; then
		# The line has no space after the last word and the newline follows directly.
		prereq_list+=( "${prereq//\$\$/\$}" )
	fi
	if [ -n "${verbose}" ]; then
		echo -n 'prereq_list='
		for ((i=0;i<${#prereq_list[*]};i++)); do
			echo -n "'${prereq_list[i]}'" " "
		done
		echo
	fi
}

result=
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

# Escape for rule.
# Parameters: $1 - Input string
#             $2 - A space follows if this parameter is non empty.
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
