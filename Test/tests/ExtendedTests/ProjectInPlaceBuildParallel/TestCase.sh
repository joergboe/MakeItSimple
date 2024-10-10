#--exclusive=true
#--variantList='default parallel fail failKeepGoing parallelFail parallelFailKeepGoing'

readonly NO_CPUS=$(cat /proc/cpuinfo | grep processor | wc -l)

OPTIONS='-s'
GOALS=
RUN_RESULT='true'
EXPECT_FAILURE=

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
	'cp "${TTRO_installDir}/ProjectInPlaceBuild/Makefile" .'
)

STEPS=(
	'[[ -n $EXPECT_FAILURE ]] || executeLogAndSuccess make $OPTIONS $GOALS'
	'[[ -z $EXPECT_FAILURE ]] || executeLogAndError make $OPTIONS $GOALS'
	'checkResult'
	'[[ -z $RUN_RESULT ]] || ./${TTRO_variantCase}'
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
			checkAllFilesExist "." "${ALL_DEP_FILE_NAMES}"
			checkAllFilesExist "." "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "." "${TTRO_variantCase}";;
		fail)
			checkFileNotExists "module3.o"
			checkFileNotExists "${TTRO_variantCase}";;
		failKeepGoing)
			checkAllFilesExist "." "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "." "${ALL_DEP_FILE_NAMES}"
			checkFileNotExists "module3.o"
			checkFileNotExists "${TTRO_variantCase}";;
		parallelFail)
			checkFileNotExists "module3.o"
			checkFileNotExists "${TTRO_variantCase}";;
		parallelFailKeepGoing)
			checkAllFilesExist "." "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "." "${ALL_DEP_FILE_NAMES}"
			checkFileNotExists "module3";;
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
	for ((i=1; i<100; i++)); do
		eval echo "\"${HEADER_TEXT}\"" > "module${i}.hpp"
		eval echo "\"${MODULE_TEXT}\"" > "module${i}.cpp"
		incl+='#include "module'${i}'.hpp"'$'\n'
		call+=$'\t''hellom'${i}'();'$'\n'
		if [[ -n $EXPECT_FAILURE && $i -eq 3 ]]; then
			echo "dsfqr qrq r q" >> "module${i}.cpp"
		else
			ALL_SOURCE_FILE_NAMES+=" module${i}.cpp"
			ALL_OBJ_FILE_NAMES+=" module${i}.o"
			ALL_DEP_FILE_NAMES+=" module${i}.dep"
		fi
	done
	echo "${incl}${TEXT1}${call}${TEXT2}" > prog.cpp
	ALL_SOURCE_FILE_NAMES+=" prog.cpp"
	ALL_OBJ_FILE_NAMES+=" prog.o"
	ALL_DEP_FILE_NAMES+=" prog.dep"
}
