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
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y opb --noprompt --copy-warn"
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
			checkFileNotExists "${BINDIR}/build/src/module30.o"
			checkFileNotExists "${BINDIR}/build/src/module56.o"
			checkFileNotExists "${BINDIR}/build/src/module96.o"
			checkFileNotExists "${BINDIR}/${TTRO_variantCase}";;
		failKeepGoing|parallelFailKeepGoing)
			checkAllFilesExist "${BINDIR}/build/src" "${ALL_OBJ_FILE_NAMES}"
			checkAllFilesExist "${BINDIR}/build/src" "${ALL_DEP_FILE_NAMES}"
			checkFileNotExists "${BINDIR}/build/src/module3.o"
			checkFileNotExists "${BINDIR}/build/src/module30.o"
			checkFileNotExists "${BINDIR}/build/src/module56.o"
			checkFileNotExists "${BINDIR}/build/src/module96.o"
			checkFileNotExists "${BINDIR}/${TTRO_variantCase}";;
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

MODULE_TEXT_AS='.section .note.GNU-stack,\"\",@progbits
.text
mess:	.ascii	\"Hello World! - hellom${i}\n\"
len	= . - mess

	.globl	hellom${i}
hellom${i}:
	movq	\$1, %rax
	movq	\$1, %rdi
	lea	mess(%rip), %rsi
	movq	\$len, %rdx
	syscall
	ret
'

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
	mkdir include src
	local incl=
	local inclc=
	local defas=
	local call=
	local -i i
	local src_suffix='cpp'
	for ((i=1; i<100; i++)); do
		if (( i < 34 )); then
			if ((i>16)); then
				src_suffix='cc'
			fi
			eval echo "\"${HEADER_TEXT}\"" > "include/module${i}.hpp"
			eval echo "\"${MODULE_TEXT}\"" > "src/module${i}.${src_suffix}"
			incl+='#include "module'${i}'.hpp"'$'\n'
			call+=$'\t''hellom'${i}'();'$'\n'
			if [[ -n $EXPECT_FAILURE && ( $i -eq 3 || $i -eq 30 ) ]]; then
				echo "dsfqr qrq r q" >> "src/module${i}.${src_suffix}"
			else
				ALL_SOURCE_FILE_NAMES+=" module${i}.${src_suffix}"
				ALL_OBJ_FILE_NAMES+=" module${i}.o"
				ALL_DEP_FILE_NAMES+=" module${i}.dep"
			fi
		elif (( i < 67 )); then
			eval echo "\"${HEADER_TEXT_C}\"" > "include/module${i}.h"
			eval echo "\"${MODULE_TEXT_C}\"" > "src/module${i}.c"
			inclc+='#include "module'${i}'.h"'$'\n'
			call+=$'\t''hellom'${i}'();'$'\n'
			if [[ -n $EXPECT_FAILURE && $i -eq 56 ]]; then
				echo "dsfqr qrq r q" >> "src/module${i}.c"
			else
				ALL_SOURCE_FILE_NAMES+=" module${i}.c"
				ALL_OBJ_FILE_NAMES+=" module${i}.o"
				ALL_DEP_FILE_NAMES+=" module${i}.dep"
			fi
		else
			eval echo "\"${MODULE_TEXT_AS}\"" > "src/module${i}.s"
			defas+="void hellom${i}();"$'\n'
			call+=$'\t''hellom'${i}'();'$'\n'
			if [[ -n $EXPECT_FAILURE && $i -eq 96 ]]; then
				echo "dsfqr qrq r q" >> "src/module${i}.s"
			else
				ALL_SOURCE_FILE_NAMES+=" module${i}.s"
				ALL_OBJ_FILE_NAMES+=" module${i}.o"
			fi
		fi
	done
	{
		echo "${incl}"
		echo -e "extern \"C\" {\n${inclc}}\n"
		echo -e "extern \"C\" {\n${defas}}\n"
		echo "${TEXT1}${call}${TEXT2}"
	} > src/prog.cpp
	ALL_SOURCE_FILE_NAMES+=" prog.cpp"
	ALL_OBJ_FILE_NAMES+=" prog.o"
	ALL_DEP_FILE_NAMES+=" prog.dep"
}
