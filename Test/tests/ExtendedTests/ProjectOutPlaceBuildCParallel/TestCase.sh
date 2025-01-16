#--exclusive=true
#--variantList='default parallel fail failKeepGoing parallelFail parallelFailKeepGoing'

NO_CPUS=$(grep -c processor /proc/cpuinfo)
readonly NO_CPUS

OPTIONS='-s'
GOALS=
RUN_RESULT='true'
EXPECT_FAILURE=
BINDIR='debug'

case ${TTRO_variantCase} in
	parallel)
		OPTIONS+=" -j ${NO_CPUS}";;
	fail)
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
	failKeepGoing)
		EXPECT_FAILURE='true'
		OPTIONS+=" --keep-going"
		RUN_RESULT=;;
	parallelFail)
		OPTIONS+=" -j ${NO_CPUS}"
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
	parallelFailKeepGoing)
		OPTIONS+=" -j ${NO_CPUS} --keep-going"
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
esac

PREPS=(
	'makeSourceFiles'
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y opbc --noprompt --copy-warn"
)

STEPS=(
	'[[ -n $EXPECT_FAILURE ]] || executeLogAndSuccess make $OPTIONS $GOALS'
	'[[ -z $EXPECT_FAILURE ]] || executeLogAndError make $OPTIONS $GOALS'
	'checkResult'
	'[[ -z $RUN_RESULT ]] || ${BINDIR}/${TTRO_variantCase}'
)

checkFileNotExists() {
	if [[ -e "$1" ]]; then
		setFailure "$1 exists"
	else
		printInfo "$1 not exists"
	fi
}

checkResult() {
	case ${TTRO_variantCase} in
		default|parallel)
			checkAllFilesExist "${BINDIR}/build/src" "${ALL_DEP_FILE_NAMES}"
			checkAllFilesExist "${BINDIR}/build/src" "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "${BINDIR}" "${TTRO_variantCase}";;
		fail|parallelFail)
			checkFileNotExists "${BINDIR}/build/src/module3.o"
			checkFileNotExists "${BINDIR}/${TTRO_variantCase}";;
		failKeepGoing|parallelFailKeepGoing)
			checkAllFilesExist "${BINDIR}/build/src" "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "${BINDIR}/build/src" "${ALL_DEP_FILE_NAMES}"
			checkFileNotExists "${BINDIR}/build/src/module3.o"
			checkFileNotExists "${BINDIR}/${TTRO_variantCase}";;
	esac
}

HEADER_TEXT='#ifndef MODULE${i}_H_
#define MODULE${i}_H_

void hellom${i}(void);

#endif /* MODULE${i}_H_ */'

MODULE_TEXT='
#include \"module${i}.h\"

#include <stdio.h>

void hellom${i}(void) {
	printf(\"Hello World module${i} !!!\n\");
	return;
}'


TEXT1='#include <stdio.h>

int main() {
	printf("Hello World Program m1 !!!\n");
'

TEXT2='	return 0;
}'

ALL_SOURCE_FILE_NAMES=
ALL_OBJ_FILE_NAMES=
ALL_DEP_FILE_NAMES=

makeSourceFiles() {
	mkdir include src
	local incl=
	local call=
	local -i i
	for ((i=1; i<100; i++)); do
		eval echo "\"${HEADER_TEXT}\"" > "include/module${i}.h"
		eval echo "\"${MODULE_TEXT}\"" > "src/module${i}.c"
		incl+='#include "module'${i}'.h"'$'\n'
		call+=$'\t''hellom'${i}'();'$'\n'
		if [[ -n $EXPECT_FAILURE && $i -eq 3 ]]; then
			echo "dsfqr qrq r q" >> "src/module${i}.c"
		else
			ALL_SOURCE_FILE_NAMES+=" module${i}.c"
			ALL_OBJ_FILE_NAMES+=" module${i}.o"
			ALL_DEP_FILE_NAMES+=" module${i}.dep"
		fi
	done
	echo "${incl}${TEXT1}${call}${TEXT2}" > src/prog.c
	ALL_SOURCE_FILE_NAMES+=" prog.c"
	ALL_OBJ_FILE_NAMES+=" prog.o"
	ALL_DEP_FILE_NAMES+=" prog.dep"
}
