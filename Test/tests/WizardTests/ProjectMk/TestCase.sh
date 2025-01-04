#--variantList='srcprdirs incprdirs incsysdirs cppflags ldflags incprdirs0 incsysdirs0 cppflags0 ldflags0 ldlibs0'

OPTIONS=
TARGET=
BINDIR=
DIRSTOCHECK=
case ${TTRO_variantSuite} in
	otocpp)
		OPTIONS='--type otocpp --no-prompt --hello-world'
		TARGET='hello';;
	ipbcpp)
		OPTIONS='--type ipbcpp --noprompt --hello-world --target-name prog1'
		TARGET='prog1';;
	opbcpp)
		OPTIONS='--type opbcpp -n --hello-world --target-name prog1 --src-dir so1 --src so2 --inc incl'
		TARGET='prog1'
		BINDIR='debug/'
		DIRSTOCHECK='so1 so2 incl';;
	opbc)
		OPTIONS='--type opbc --noprompt --hello-world --target-name prog1 --src-dir so1 --src so2 --inc incl'
		TARGET='prog1'
		BINDIR='debug/'
		DIRSTOCHECK='so1 so2 incl';;
	opb)
		OPTIONS='--type opb --noprompt --hello-world --target-name prog1 --src-dir so1 --src so2 --inc incl'
		TARGET='prog1'
		BINDIR='debug/'
		DIRSTOCHECK='so1 so2 incl';;
	*)
		printErrorAndExit "Invalid suite variant ${TTRO_variantSuite}";;
esac

OPTIONS+=' --incsysdirs isys44 --cc gcc --cxx g++ --cppflags -DMYHELLO=xxxxx --cxxflags --std=c++11 --cflags --std=c11 --ldflags -Ldd44 --ldlibs -lrt'
OPTIONS2='--copy-warn --overwrite'

PRENTRY=
MAKEOPTION=
MAKENOTOPTION=
case ${TTRO_variantCase} in
	srcprdirs)
		if [[ ${TTRO_variantSuite} != opb* ]]; then
			setSkip "Src dirs not valid here"
		fi
		OPTIONSX="${OPTIONS} -s so3"
		PRENTRY='SRCDIRS = so1 so2'
		DIRSTOCHECK+=' so3';;
	incprdirs)
		if [[ ${TTRO_variantSuite} != opb* ]]; then
			setSkip "Inc dirs not valid here"
		fi
		OPTIONSX="${OPTIONS} -i incl2"
		PRENTRY='INCDIRS = incl incl2'
		DIRSTOCHECK+=' incl2'
		MAKEOPTION='*hello.c*-iquoteincl -iquoteincl2*';;
	incsysdirs)
		OPTIONSX="${OPTIONS} --incsysdirs isys55"
		PRENTRY='INCSYSDIRS = isys44 isys55'
		MAKEOPTION='*hello.c*-Iisys44 -Iisys55*';;
	cppflags)
		OPTIONSX="${OPTIONS} --cppflags -DMYHELLO2=xxxxx"
		PRENTRY='CPPFLAGS = -DMYHELLO=xxxxx -DMYHELLO2=xxxxx'
		MAKEOPTION='*hello.c*-DMYHELLO=xxxxx -DMYHELLO2=xxxxx*';;
	ldflags)
		OPTIONSX="${OPTIONS} --ldflags -Ldd55"
		PRENTRY='LDFLAGS = -Ldd44 -Ldd55'
		MAKEOPTION='*-Ldd44 -Ldd55*';;
	incprdirs0)
		if [[ ${TTRO_variantSuite} != opb* ]]; then
			setSkip "Inc dirs not valid here"
		fi
		OPTIONSX="${OPTIONS/--inc\ incl/}"
		PRENTRY='INCDIRS = '
		MAKENOTOPTION='*-iquoteincl*';;
	incsysdirs0)
		OPTIONSX="${OPTIONS/--incsysdirs\ isys44/}"
		PRENTRY='INCSYSDIRS = '
		MAKENOTOPTION='*-Iisys44*';;
	cppflags0)
		OPTIONSX="${OPTIONS/--cppflags\ -DMYHELLO=xxxxx/}"
		PRENTRY='CPPFLAGS = '
		MAKENOTOPTION='*-DMYHELLO*';;
	ldflags0)
		OPTIONSX="${OPTIONS/--ldflags\ -Ldd44/}"
		PRENTRY='LDFLAGS = '
		MAKENOTOPTION='*-Ldd44*';;
	ldlibs0)
		OPTIONSX="${OPTIONS//--ldlibs\ -lrt/}"
		PRENTRY='LDLIBS = '
		MAKENOTOPTION='*-lrt*';;
	*)
		printErrorAndExit "Invalid case variant ${TTRO_variantCase}";;
esac

STEPS=(
	'executeLogAndSuccess "${TTRO_installDir}/bin/mktsimple" ${OPTIONS}'
	'checkOutput'
	'checkProjectMk'
	"if [[ -d mktsimple ]]; then setFailure 'Makefile directory exists!'; fi"
	'executeLogAndSuccess "${TTRO_installDir}/bin/mktsimple" ${OPTIONS} --debug ${OPTIONS2}'
	'checkOutput'
	"checkAllFilesExist \"mktsimple\" 'warnings.cc-12.mk warnings.cc-7.mk warnings.clang-17.mk warnings.g++-12.mk warnings.g++-7.mk warnings.gcc-14.mk warnings.cc-13.mk warnings.clang-13.mk warnings.clang-18.mk warnings.g++-13.mk warnings.gcc-12.mk warnings.gcc-7.mk warnings.cc-14.mk warnings.clang-14.mk warnings.clang-19.mk warnings.g++-14.mk warnings.gcc-13.mk'"
	'THEFILES=$(echo project.mk.~* Makefile.~*)'
	'if [[ -n ${THEFILES} ]]; then setFailure "Backupfiles exist: ${THEFILES}"; fi'
	'thirdTest'
	'checkProjectMk'
	'linewisePatternMatchInterceptAndSuccess "project.mk" "true" "${PRENTRY}"'
	'THEFILES=$(echo Makefile.~*)'
	'if [[ -n ${THEFILES} ]]; then setFailure "Backupfiles exist: ${THEFILES}"; fi'
	'checkDirs'
	'executeLogAndSuccess make'
	'if [[ -n ${MAKEOPTION} ]]; then linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" true "${MAKEOPTION}"; fi'
	'if [[ -n ${MAKENOTOPTION} ]]; then linewisePatternMatchInterceptAndError "${TT_evaluationFile}" false "${MAKENOTOPTION}"; fi'
)

thirdTest() {
	case ${TTRO_variantCase} in
		srcprdirs|incprdirs|incsysdirs|cppflags|ldflags)
		if ! "${TTRO_installDir}/bin/mktsimple" ${OPTIONSX} ${OPTIONS2}; then
			setFailure "$? returned from mktsimple"
		fi;;
	incprdirs0)
		if ! "${TTRO_installDir}/bin/mktsimple" ${OPTIONSX} --inc '' ${OPTIONS2}; then
			setFailure "$? returned from mktsimple"
		fi;;
	incsysdirs0)
		if ! "${TTRO_installDir}/bin/mktsimple" ${OPTIONSX} --incsysdirs '' ${OPTIONS2}; then
			setFailure "$? returned from mktsimple"
		fi;;
	cppflags0)
		if ! "${TTRO_installDir}/bin/mktsimple" ${OPTIONSX} --cppflags '' ${OPTIONS2}; then
			setFailure "$? returned from mktsimple"
		fi;;
	ldflags0)
		if ! "${TTRO_installDir}/bin/mktsimple" ${OPTIONSX} --ldflags '' ${OPTIONS2}; then
			setFailure "$? returned from mktsimple"
		fi;;
	ldlibs0)
		if ! "${TTRO_installDir}/bin/mktsimple" ${OPTIONSX} --ldlibs '' ${OPTIONS2}; then
			setFailure "$? returned from mktsimple"
		fi;;
	*)
		printErrorAndExit "Invalid case variant ${TTRO_variantCase}";;
esac
}

checkOutput() {
	linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '* All done *'
	return 0
}

checkProjectMk() {
	case ${TTRO_variantSuite} in
		otocpp)
			linewisePatternMatchInterceptAndSuccess "project.mk" 'true'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt';;
		ipbcpp)
			linewisePatternMatchInterceptAndSuccess "project.mk" 'true'\
			'TARGET = prog1'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt';;
		opbcpp)
			linewisePatternMatchInterceptAndSuccess "project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt';;
		opbc)
			linewisePatternMatchInterceptAndSuccess "project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CC = gcc'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CFLAGS = --std=c11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt';;
		opb)
			linewisePatternMatchInterceptAndSuccess "project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CC = gcc'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CFLAGS = --std=c11'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt';;
	*)
		printErrorAndExit "Invalid suite variant ${TTRO_variantSuite}";;
	esac
}

checkDirs() {
	local dd
	for dd in ${DIRSTOCHECK}; do
		if [[ -d "${dd}" ]]; then
			echo "Dir ${dd} exists"
		else
			setFailure "Dir ${dd} does not exists"
		fi
	done
}