#!/usr/bin/env bash

set -o nounset;

readonly mkts='mktsimple'

usage() {
	echo
	echo "		Install Make It Simple mktsimple"
	echo
	echo "Usage: ${mkts} [OPTION]... [<install_dir>]"
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
	DEFAULTINSTALLDIR="${mkts}"
	installUser=$(whoami)
	if [[ $installUser == 'root' ]]; then
		destination="/usr/local"
	else
		destination="$HOME/$DEFAULTINSTALLDIR"
	fi
fi
if [[ -z "${destination}" ]]; then
	echo "ERROR: Destination directory is required!" >&2
	exit 2
fi

#Get version information from own filename
declare -r commandname="${0##*/}"
echo "$commandname"
if [[ $commandname =~ ${mkts}_installer_v([0-9]+)\.([0-9]+)\.([0-9]+)\.sh ]]; then
	major="${BASH_REMATCH[1]}"
	minor="${BASH_REMATCH[2]}"
	fix="${BASH_REMATCH[3]}"
	echo "Install mktsimple release $major.$minor.$fix"
elif [[ $commandname =~ ${mkts}_installer_v([0-9]+)\.([0-9]+)\.([0-9]+.+)\.sh ]]; then
	major="${BASH_REMATCH[1]}"
	minor="${BASH_REMATCH[2]}"
	fix="${BASH_REMATCH[3]}"
	echo "Install ${mkts} development version $major.$minor.$fix"
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
if [[ -f "${bindir}/${mkts}" || -d "${includedir}/${mkts}" || -d "${sharedir}/${mkts}" || -d "${docdir}/${mkts}" ]]; then
	some_files_exist='true'
	echo "There are already some files installed!"
	ls "${bindir}/${mkts}" "${includedir}/${mkts}" "${sharedir}/${mkts}" "${docdir}/${mkts}"
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
	rm -fv "${bindir}/${mkts}" || ((failures++))
	rm -fv "${includedir}/${mkts}/"* || ((failures++))
	rmdir -v "${includedir}/${mkts}" || ((failures++))
	rm -fv "${sharedir}/${mkts}/"* || ((failures++))
	rmdir -v "${sharedir}/${mkts}" || ((failures++))
	rm -fv "${docdir}/${mkts}/"* || ((failures++))
	rmdir -v "${docdir}/${mkts}" || ((failures++))
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
	mv -v -f "${tempdir}/include/${mkts}" "${includedir}" || exit_function
	mv -v -f "${tempdir}/share/${mkts}" "${sharedir}" || exit_function
	mv -v -f "${tempdir}/doc/${mkts}" "${docdir}" || exit_function

	echo -e "\n***********************************************************"
	echo -e   "	Installation complete. Target bin directory $bindir"
	echo -e   "	You can execute the ${mkts} help function:"
	echo -e   "	${bindir}/${mkts} --help"
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
