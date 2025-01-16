#--exclusive=true
#--variantList='default parallel fail failKeepGoing parallelFail parallelFailKeepGoing'

NO_CPUS=$(grep -c processor /proc/cpuinfo)
readonly NO_CPUS

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
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y otocpp --noprompt --copy-warn"
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
		fail|parallelFail)
			checkFileNotExists "module3"
			checkFileNotExists "module96";;
		failKeepGoing|parallelFailKeepGoing)
			checkAllFilesExist "." "${ALL_EXE_FILE_NAMES}"
			checkFileNotExists "module3"
			checkFileNotExists "module96";;
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
	local src_suffix='cpp'
	for ((i=1; i<100; i++)); do
		if ((i>50)); then
			src_suffix='cc'
		fi
		echo "${TEXT/module1./module${i}}" > "module${i}.${src_suffix}"
		if [[ -n $EXPECT_FAILURE && ( $i -eq 3 || $i -eq 96 ) ]]; then
			echo "dsfqr qrq r q" >> "module${i}.${src_suffix}"
		else
			ALL_SOURCE_FILE_NAMES+=" module${i}.${src_suffix}"
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