#--exclusive=true
#--variantList='default parallel fail failKeepGoing parallelFail parallelFailKeepGoing'

NO_CPUS=$(grep -c processor /proc/cpuinfo)
readonly NO_CPUS

ALL_SOURCE_FILE_NAMES=
ALL_EXE_FILE_NAMES=
ALL_GOOD_EXE_FILE_NAMES=

OPTIONS=
GOALS=
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
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y otocpp --noprompt"
)

STEPS=(
	"executeLogAndSuccess make -j ${NO_CPUS} $OPTIONS $GOALS"
	'[[ -z $EXPECT_FAILURE ]] || { echo "bla dsds aaa" >> module3.cpp; echo "bla dsds aaa" >> module96.cc; }'
	'checkAllFilesExist "." "${ALL_EXE_FILE_NAMES}"'
	'[[ -n $EXPECT_FAILURE ]] || executeLogAndSuccess make $OPTIONS $GOALS'
	'[[ -z $EXPECT_FAILURE ]] || executeLogAndError make $OPTIONS $GOALS'
	'checkResult'
	'runAll'
)

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
			checkAllFilesExist "." "${ALL_EXE_FILE_NAMES}";;
		fail|parallelFail)
			checkAllFilesExist "." "${ALL_GOOD_EXE_FILE_NAMES}"
			checkFileNotExistsOr "module3" "module96";;
		failKeepGoing|parallelFailKeepGoing)
			checkAllFilesExist "." "${ALL_GOOD_EXE_FILE_NAMES}"
			checkFileNotExistsAnd "module3" "module96";;
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
		ALL_SOURCE_FILE_NAMES+=" module${i}.${src_suffix}"
		ALL_EXE_FILE_NAMES+=" module${i}"
		if [[ -n ${EXPECT_FAILURE} && ( ${i} == 3 || ${i} == 96 ) ]]; then
			:
		else
			ALL_GOOD_EXE_FILE_NAMES+=" module${i}"
		fi
	done
}

runAll() {
	local -i i
	for X in ${ALL_GOOD_EXE_FILE_NAMES}; do
		"./${X}"
	done
}