#!/usr/bin/env bash

set -o errexit; set -o nounset;

declare -r releasedir='releases'
declare -r docdir='doc'
declare -r mks='mktsimple'

temp="$(grep "${mks}_version :=" share/mktsimple/one_to_one_cpp.mk)" || { echo "ERROR: No version" >&2; exit 1; }
release_version="${temp##* }"

echo
echo "Build release package version v${release_version}"
echo

pr="Is this correct: y/e "
response=''
while [[ ("${response}" != 'y') && ("${response}" != 'yes') ]]; do
	read -r -p "${pr}" || exit 2
	response="${REPLY,,}"
	if [[ ("${response}" == 'e') || ("${response}" == 'exit') ]]; then
		echo "Abort"
		exit 2
	fi
done

for x in in_place_cpp.mk out_place_c.mk out_place_cpp.mk out_place.mk; do
	temp="$(grep "${mks}_version :=" share/mktsimple/${x})" || { echo "ERROR: No version in ${x}" >&2; exit 1; }
	release_version_x="${temp##* }"
	if [[ "${release_version}" != "${release_version_x}" ]]; then
		echo "ERROR: Version info ${release_version_x} of ${x} does not match!" >&2
		exit 1
	fi
done

commitstatus=$(git status --porcelain)
if [[ $commitstatus ]]; then
	echo "Repository has uncommited changes:"
	echo "$commitstatus"
	pr="To produce the release anyway press y/e "
	response=''
	while [[ ("${response}" != 'y') && ("${response}" != 'yes') ]]; do
		read -r -p "${pr}" || exit 2
		response="${REPLY,,}"
		if [[ ("${response}" == 'e') || ("${response}" == 'exit') ]]; then
			echo "Abort"
			exit 2
		fi
	done
fi

commithash=$(git rev-parse HEAD)
echo "RELEASE.INFO commithash=$commithash"
mkdir -p "${docdir}/${mks}"
echo -e "${mks}_version=${release_version}\n=$commithash" > "${docdir}/${mks}/RELEASE.INFO"
cp README.md "${docdir}/${mks}"

fname="${mks}_installer_v${release_version}.sh"

mkdir -p "$releasedir"
tar cvJf "$releasedir/tmp.tar.xz" --exclude=.gitignore bin share include "${docdir}"

cat tools/selfextract.sh releases/tmp.tar.xz > "$releasedir/$fname"

chmod +x "$releasedir/$fname"

rm "$releasedir/tmp.tar.xz"

echo
echo "*************************************************"
echo "Success build release package '$releasedir/$fname'"
echo "*************************************************"

exit 0
