#!/usr/bin/env bash

set -o nounset;

readonly mks='mktsimple'

usage() {
	if [[ -n $help || -n $wrongInvocation ]]; then
		myCommand=${0##*/}
		echo
		echo "		Install Make It Simple mktsimple"
		echo
		echo "Usage: $myCommand [OPTION]... [<install_dir>]"
		echo
		echo "		If no command line parameter is specified the installation is done interactive"
		echo
		echo "Options:"
		echo
		echo "		-h|--help        - Display help"
		echo "		-i|--install     - Start an installation (default)"
		echo "		-u|--uninstall   - Uninstall the program"
		echo "		-d|--delete      - Delete installed files before the installation is done"
		echo "		install_dir      - The base dir of the installation"
		echo
		if [[ -n $wrongInvocation ]]; then
			exit 2
		else
			exit 0
		fi
	fi
}

wrongInvocation=
delete_requested=
install_requested='true'
uninstall_requestd=
interactive='true'
help_requested=
destination=
while [[ $# -gt 0 ]]; do
	interactive=''
	case "$1" in
		'-h'|'--help')
			help_requested='true';;
		'-i'|'--install')
			install_requested='true'
			uninstall_requestd=;;
		'-u'|'--uninstall')
			install_requested=''
			uninstall_requestd='true';;
		'-d'|'--delete')
			delete_requested='true';;
		*)
			destination="$1"
	esac
	shift
done

if [[ -n $help_requested ]]; then
	usage
fi

if [[ -n $interactive ]]; then
	DEFAULTINSTALLDIR="${mks}"
	installUser=$(whoami)
	if [[ $installUser == 'root' ]]; then
		destination="/usr/local"
	else
		destination="$HOME/$DEFAULTINSTALLDIR"
	fi
else
	destination="$1"
fi

#Get version information from own filename
declare -r commandname="${0##*/}"
echo "$commandname"
if [[ $commandname =~ ${mks}_installer_v([0-9]+)\.([0-9]+)\.([0-9]+)\.sh ]]; then
	major="${BASH_REMATCH[1]}"
	minor="${BASH_REMATCH[2]}"
	fix="${BASH_REMATCH[3]}"
	echo "Install mktsimple release $major.$minor.$fix"
elif [[ $commandname =~ ${mks}_installer_v([0-9]+)\.([0-9]+)\.([0-9]+.+)\.sh ]]; then
	major="${BASH_REMATCH[1]}"
	minor="${BASH_REMATCH[2]}"
	fix="${BASH_REMATCH[3]}"
	echo "Install ${mks} development version $major.$minor.$fix"
else
	echo "ERROR: This is no valid install package commandname=$commandname" >&2
	exit 1
fi

if [[ -n $interactive ]]; then
	echo
	response=
	while [[ -z "${response}" ]]; do
		read -r -p "Install or uninstall? (install//uninstall/exit) [i/u/e] " || exit 3
		response="${REPLY,,}"
		if [[ ("${response}" == 'e') || ("${response}" == 'exit') ]]; then
			echo "Abort"
			exit 3
		elif [[ $response == "i" || $response == "install" ]]; then
			install_requested='true'
			uninstall_requestd=
			display="Install to"
			break
		elif [[ $response == "u" || $response == "uninstall" ]]; then
			install_requested=''
			uninstall_requestd='true'
			display="Uninstall from"
			break
		else
			response=
		fi
	done

	echo
	response=''
	while [[ $response != "y" && $response != "yes" ]]; do
		pr="${display} directory $destination (yes/no/exit) [y/n/e] "
		read -r -p "${pr}" || exit 3;
		response="${REPLY,,}"
		if [[ ("${response}" == 'e') || ("${response}" == 'exit') ]]; then
			echo "Abort"
			exit 3
		fi
		if [[ $response == "n" || $response == "no" ]]; then
			read -r -p "Enter installation directory: " || exit 3
			tempdir="$REPLY"
			if [[ "$tempdir" != /* ]]; then
				echo "Use a absolute path not $tempdir"
			else
				destination="$tempdir"
			fi
		fi
	done

	echo
	response=''
	while [[ $response != "y" && $response != "yes" ]]; do
		read -r -p "${display} directory $destination is this correct? (yes/exit) [y/e] " || exit 3
		response="${REPLY,,}"
		if [[ ("${response}" == 'e') || ("${response}" == 'exit') ]]; then
			echo "Abort"
			exit 3
		fi
	done
fi

if [[ $destination != /* ]]; then
	echo "Use a absolute path not $destination" >&2
	exit 1
fi

readonly bindir="${destination}/bin"
readonly includedir="${destination}/include"
readonly sharedir="${destination}/share"
readonly docdir="${sharedir}/doc/packages"

if [[ -n "${install_requested}" ]]; then
	tempdir="$(mktemp -d)"
	echo "use tempdir=$tempdir"

	#Determine the line with the archive marker
	declare -i archiveline=0
	declare -i line=0
	while read -r; do
		line=$((line + 1 ))
		if [[ $REPLY == __ARCHIVE_MARKER__ ]]; then
			if [[ $archiveline -eq 0 ]]; then  # only the first marker counts
				archiveline="$line"
			fi
		fi
	done < "${0}"
	archiveline=$((archiveline + 1))

	# extract to tempdir
	tail -n+${archiveline} "${0}" | tar xJv --no-same-owner -C "${tempdir}"
fi

some_files_exist=
if [[ -f "${bindir}/${mks}" || -d "${includedir}/${mks}" || -d "${sharedir}/${mks}" || -d "${docdir}/${mks}" ]]; then
	some_files_exist='true'
	echo "There are already some files installed!"
	ls "${bindir}/${mks}" "${includedir}/${mks}" "${sharedir}/${mks}" "${docdir}/${mks}"
	if [[ -n $install_requested ]]; then
		if [[ -n $interactive ]]; then
			echo
			response=''
			while [[ $response != "y" && $response != "yes" ]]; do
				read -r -p "Delete already installed files in ${destination} (yes/exit) [y/e] " || exit 3
				response="${REPLY,,}"
				if [[ ("${response}" == 'e') || ("${response}" == 'exit') ]]; then
					echo "Abort"
					exit 3
				fi
			done
			delete_requested='true'
		else
			if [[ -n "${install_requested}" && -z "${delete_requested}" ]]; then
				echo "There are already some files installed but deletion is not requested! Exit" >&2
				exit 1
			fi
		fi
	fi
fi

declare -i failures=0
# cleanup
if [[ -n $some_files_exist && (-n $delete_requested || -n $uninstall_requestd) ]]; then
	rm -fv "${bindir}/${mks}" || ((failures++))
	rm -fv "${includedir}/${mks}/"* || ((failures++))
	rmdir -v "${includedir}/${mks}" || ((failures++))
	rm -fv "${sharedir}/${mks}/"* || ((failures++))
	rmdir -v "${sharedir}/${mks}" || ((failures++))
	rm -fv "${docdir}/${mks}/"* || ((failures++))
	rmdir -v "${docdir}/${mks}" || ((failures++))
fi

exit_function() {
	{
		echo -e "\n********************************"
		echo -e   "***** Installation failed! *****"
		echo -e   "********************************\n"
	} >&2
	exit 1
}

if [[ -n $install_requested ]]; then
	# create directories
	[[ -d "${bindir}" ]] || mkdir -v -p "${bindir}" || exit_function
	[[ -d "${includedir}" ]] || mkdir -v -p "${includedir}" || exit_function
	[[ -d "${sharedir}" ]] || mkdir -v -p "${sharedir}" || exit_function
	[[ -d "${docdir}" ]] || mkdir -v -p "${docdir}" || exit_function

	#move the targets
	mv -v -f "${tempdir}/bin/"* "${bindir}" || exit_function
	mv -v -f "${tempdir}/include/${mks}" "${includedir}" || exit_function
	mv -v -f "${tempdir}/share/${mks}" "${sharedir}" || exit_function
	mv -v -f "${tempdir}/doc/${mks}" "${docdir}" || exit_function

	echo -e "\n***********************************************************"
	echo -e   "	Installation complete. Target bin directory $bindir"
	echo -e   "	You can execute the ${mks} help function:"
	echo -e   "	${bindir}/${mks} --help"
	if ((failures>0)); then
		echo -e   "	**** Failures: ${failures} ****"
	fi
	echo -e   "***********************************************************\n"
fi

if [[ -n $uninstall_requestd ]]; then
	echo -e "\n************************************"
	echo -e   "	Uninstall ${destination}"
	if ((failures>0)); then
		echo -e   "	**** Failures: ${failures} ****"
	else
		echo -e   "	done"
	fi
	echo -e   "************************************\n"
fi

if [[ $failures == '0' ]]; then
	exit 0
else
	exit 4
fi

__ARCHIVE_MARKER__
