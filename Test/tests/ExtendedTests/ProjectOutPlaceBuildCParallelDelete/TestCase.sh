#--exclusive=true
#--variantList='default parallel fail failKeepGoing parallelFail parallelFailKeepGoing'

NO_CPUS=$(grep -c processor /proc/cpuinfo)
readonly NO_CPUS

ALL_SOURCE_FILE_NAMES=
ALL_DEP_FILE_NAMES=
ALL_OBJ_FILE_NAMES=
ALL_GOOD_OBJ_FILE_NAMES=

OPTIONS=
GOALS=
RUN_RESULT='true'
EXPECT_FAILURE=

case ${TTRO_variantCase} in
	parallel)
		OPTIONS+=" -j ${NO_CPUS}";;
	fail)
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
	failKeepGoing*)
		EXPECT_FAILURE='true'
		OPTIONS+=" --keep-going"
		RUN_RESULT=;;
	parallelFail)
		OPTIONS+=" -j ${NO_CPUS}"
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
	parallelFailKeepGoing*)
		OPTIONS+=" -j ${NO_CPUS} --keep-going"
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
esac

PREPS=(
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y opbc --noprompt"
	'makeSourceFiles'
)

STEPS=(
	"executeLogAndSuccess make -j ${NO_CPUS} $OPTIONS $GOALS"
	'invalidateModules'
	'checkAllFilesExist "debug/build/src" "${ALL_DEP_FILE_NAMES}"'
	'checkAllFilesExist "debug/build/src" "${ALL_OBJ_FILE_NAMES}"'
	'checkAllFilesExist "debug" "${TTRO_variantCase}"'
	'[[ -n $EXPECT_FAILURE ]] || executeLogAndSuccess make $OPTIONS $GOALS'
	'[[ -z $EXPECT_FAILURE ]] || executeLogAndError make $OPTIONS $GOALS'
	'checkResult'
	'[[ -z $RUN_RESULT ]] || debug/${TTRO_variantCase}'
)

appendGarbage() {
	printInfo "Append garbage to $1"
	echo "bla dsds aaa" >> "$1"
}

invalidateModules() {
	case ${TTRO_variantCase} in
		fail|failKeepGoing|parallelFail|parallelFailKeepGoing)
			appendGarbage 'src/module3.c'
			appendGarbage 'src/module96.c';;
		*)
			printInfo 'Nothing to change';;
	esac
}

checkFileNotExistsAnd() {
	while (($# > 0)); do
		if [[ -e "$1" ]]; then
			setFailure "$1 exists"
		else
			printInfo "$1 not exists and"
		fi
		shift
	done
}

checkFileNotExistsOr() {
	local file_not_found=
	local files_exists=
	while (($# > 0)); do
		if [[ -e "$1" ]]; then
			files_exists+="$1 "
		else
			file_not_found+="$1 "
		fi
		shift
	done
	if [[ -z "${file_not_found}" ]]; then
		setFailure "All those files exist: ${files_exists}"
	else
		printInfo "checkFileNotExistsOr: ${file_not_found} not exist"
	fi
}

checkResult() {
	case ${TTRO_variantCase} in
		default|parallel)
			checkAllFilesExist "debug/build/src" "${ALL_DEP_FILE_NAMES}"
			checkAllFilesExist "debug/build/src" "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "debug" "${TTRO_variantCase}";;
		fail|parallelFail)
			checkAllFilesExist "debug/build/src" "${ALL_GOOD_OBJ_FILE_NAMES}"
			checkFileNotExistsOr "debug/build/src/module3.o" "debug/build/src/module96.o"
			checkFileNotExistsAnd "debug/${TTRO_variantCase}";;
		failKeepGoing|parallelFailKeepGoing)
			checkAllFilesExist "debug/build/src" "${ALL_GOOD_OBJ_FILE_NAMES}"
			checkFileNotExistsAnd "debug/build/src/module3.o" "debug/build/src/module96.o"
			checkFileNotExistsAnd "debug/${TTRO_variantCase}";;
	esac
}

HEADER_TEXT_C='#ifndef MODULE${i}_H_
#define MODULE${i}_H_

void hellom${i}(void);

#endif /* MODULE${i}_H_ */'

MODULE_TEXT_C='
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
	local inclc=
	local call=
	local -i i
	for ((i=1; i<100; i++)); do
		eval echo "\"${HEADER_TEXT_C}\"" > "include/module${i}.h"
		eval echo "\"${MODULE_TEXT_C}\"" > "src/module${i}.c"
		inclc+='#include "module'${i}'.h"'$'\n'
		call+=$'\t''hellom'${i}'();'$'\n'
		ALL_SOURCE_FILE_NAMES+=" module${i}.c"
		ALL_OBJ_FILE_NAMES+=" module${i}.o"
		ALL_DEP_FILE_NAMES+=" module${i}.dep"
		if [[ -n $EXPECT_FAILURE && ( $i -eq 3 || $i -eq 96 ) ]]; then
			:
		else
			ALL_GOOD_OBJ_FILE_NAMES+=" module${i}.o"
		fi
	done
	{
		echo -e "${inclc}\n"
		echo "${TEXT1}${call}${TEXT2}"
	} > 'src/prog.c'
	ALL_SOURCE_FILE_NAMES+=" prog.c"
	ALL_OBJ_FILE_NAMES+=" prog.o"
	ALL_DEP_FILE_NAMES+=" prog.dep"
}
