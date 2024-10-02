#--exclusive=true
#--variantList='default parallel fail failKeepGoing parallelFail parallelFailKeepGoing'

readonly NO_CPUS=$(cat /proc/cpuinfo | grep processor | wc -l)
ALL_SOURCE_FILE_NAMES=
ALL_EXE_FILE_NAMES=

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
		OPTIONS+=" --keep-going";;
	parallelFail)
		OPTIONS+=" -j ${NO_CPUS}"
		EXPECT_FAILURE='true'
		RUN_RESULT=;;
	parallelFailKeepGoing)
		OPTIONS+=" -j ${NO_CPUS} --keep-going"
		EXPECT_FAILURE='true';;
esac

PREPS=(
	'makeSourceFiles'
	'cp "${TTRO_installDir}/OneToOne/Makefile" .'
)

STEPS=(
	'[[ -n $EXPECT_FAILURE ]] || executeLogAndSuccess make $OPTIONS $GOALS'
	'[[ -z $EXPECT_FAILURE ]] || executeLogAndError make $OPTIONS $GOALS'
	'checkResult'
	'[[ -z $RUN_RESULT ]] || runAll'
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
			checkAllFilesExist "." "${ALL_EXE_FILE_NAMES}";;
		fail)
			checkFileNotExists "module3";;
		failKeepGoing)
			checkAllFilesExist "." "${ALL_EXE_FILE_NAMES}"
			checkFileNotExists "module3";;
		parallelFail)
			checkFileNotExists "module3";;
		parallelFailKeepGoing)
			checkAllFilesExist "." "${ALL_EXE_FILE_NAMES}"
			checkFileNotExists "module3";;
	esac
}

TEXT='#include <iostream>

using namespace std;

int main() {
	cout << "Hello World Program module1. !!!" << endl;
	return 0;
}'

makeSourceFiles() {
	local -i i
	for ((i=1; i<100; i++)); do
		echo "${TEXT/module1./module${i}}" > "module${i}.cpp"
		if [[ -n $EXPECT_FAILURE && $i -eq 3 ]]; then
			echo "dsfqr qrq r q" >> "module${i}.cpp"
		else
			ALL_SOURCE_FILE_NAMES+=" module${i}.cpp"
			ALL_EXE_FILE_NAMES+=" module${i}"
		fi
	done
}

runAll() {
	local -i i
	for X in ${ALL_EXE_FILE_NAMES}; do
		"./${X}"
	done
}