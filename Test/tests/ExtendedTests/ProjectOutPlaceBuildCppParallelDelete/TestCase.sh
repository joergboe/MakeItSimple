#--exclusive=true
#--variantList='default parallel fail failKeepGoing failKeepGoing3 failKeepGoing96 parallelFail parallelFailKeepGoing parallelFailKeepGoing3 parallelFailKeepGoing96'

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
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y opbcpp --noprompt --copy-warn"
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
			appendGarbage 'src/module3.cpp'
			appendGarbage 'src/module96.cc';;
		*3)
			appendGarbage 'src/module3.cpp';;
		*96)
			appendGarbage 'src/module96.cc';;
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
		failKeepGoing3|parallelFailKeepGoing3)
			checkAllFilesExist "debug/build/src" "${ALL_GOOD_OBJ_FILE_NAMES}"
			checkFileNotExistsAnd "debug/build/src/module3.o"
			checkFileNotExistsAnd "debug/${TTRO_variantCase}";;
		failKeepGoing96|parallelFailKeepGoing96)
			checkAllFilesExist "debug/build/src" "${ALL_GOOD_OBJ_FILE_NAMES}"
			checkFileNotExistsAnd "debug/build/src/module96.o"
			checkFileNotExistsAnd "debug/${TTRO_variantCase}";;
	esac
}

HEADER_TEXT='#ifndef MODULE${i}_HPP_
#define MODULE${i}_HPP_

void hellom${i}();

#endif /* MODULE${i}_HPP_ */'

MODULE_TEXT='
#include \"module${i}.hpp\"

#include <iostream>

using namespace std;

void hellom${i}() {
	cout << \"Hello World module${i} !!!\" << endl;
	return;
}'

TEXT1='#include <iostream>

using namespace std;

int main() {
	cout << "Hello World Program m1 !!!" << endl;
'

TEXT2='	return 0;
}'

ALL_SOURCE_FILE_NAMES=
ALL_OBJ_FILE_NAMES=
ALL_DEP_FILE_NAMES=

makeSourceFiles() {
	local incl=
	local call=
	local -i i
	local src_suffix='cpp'
	for ((i=1; i<100; i++)); do
		if ((i>50)); then
			src_suffix='cc'
		fi
		eval echo "\"${HEADER_TEXT}\"" > "include/module${i}.hpp"
		eval echo "\"${MODULE_TEXT}\"" > "src/module${i}.${src_suffix}"
		incl+='#include "module'${i}'.hpp"'$'\n'
		call+=$'\t''hellom'${i}'();'$'\n'
		ALL_SOURCE_FILE_NAMES+=" module${i}.${src_suffix}"
		ALL_OBJ_FILE_NAMES+=" module${i}.o"
		ALL_DEP_FILE_NAMES+=" module${i}.dep"
		if [[ -n $EXPECT_FAILURE && ( $i -eq 3 || $i -eq 96 ) ]]; then
			:
		else
			ALL_GOOD_OBJ_FILE_NAMES+=" module${i}.o"
		fi
	done
	echo "${incl}${TEXT1}${call}${TEXT2}" > 'src/prog.cpp'
	ALL_SOURCE_FILE_NAMES+=" prog.cpp"
	ALL_OBJ_FILE_NAMES+=" prog.o"
	ALL_GOOD_OBJ_FILE_NAMES+=" prog.o"
	ALL_DEP_FILE_NAMES+=" prog.dep"
}
