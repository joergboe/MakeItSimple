#--variantList='help typehelp invalidOption missingValue otocpphello ipbcpphello opbcpphello opbchello opbhello otocppproj1 ipbcppproj1 opbcppproj1 opbcproj1 opbproj1'

OPTIONS=
EXPECT_FAILURE=
HELLO_WORLD=
PROJECT_DIR='.'
BINDIR=
TARGET="${TTRO_variantCase}"
case ${TTRO_variantCase} in
	help)
		OPTIONS='--help';;
	typehelp)
		OPTIONS='--help=type';;
	invalidOption)
		OPTIONS='--other'
		EXPECT_FAILURE='true';;
	missingValue)
		OPTIONS='--src-dir'
		EXPECT_FAILURE='true';;
	otocpp*)
		OPTIONS='--type otocpp --no-prompt'
		TARGET='hello';;
	ipbcpp*)
		OPTIONS='--type ipbcpp --noprompt';;
	opbcpp*)
		OPTIONS='--type opbcpp -n';;
	opbc*)
		OPTIONS='--type opbc --noprompt';;
	opb*)
		OPTIONS='--type opb --noprompt';;
	*)
		printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
esac

case ${TTRO_variantCase} in
	*hello)
		OPTIONS+=' --hello-world'
		HELLO_WORLD='true';;
	*proj1)
		OPTIONS+=' --hello-world --project-dir project1 --incsysdirs isys44 --cc gcc --cxx g++ --cppflags -DMYHELLO=xxxxx'
		OPTIONS+=' --cxxflags --std=c++11 --cflags --std=c11 --ldflags -Ldd44'
		PROJECT_DIR='project1'
		HELLO_WORLD='true';;
esac

case ${TTRO_variantCase} in
	opb*)
		BINDIR='debug/'
		HELLO_WORLD='true';;
esac

case ${TTRO_variantCase} in
	ipbcppproj1|opbcppproj1|opbcproj1|opbproj1)
		OPTIONS+=' --target-name prog1'
		TARGET='prog1';;
esac

case ${TTRO_variantCase} in
	opbcppproj1|opbcproj1|opbproj1)
		OPTIONS+=' --src-dir so1 --src-dir so2 --inc incl';;
esac

if [[ -z ${EXPECT_FAILURE} ]]; then
	STEPS=( "executeLogAndSuccess \"${TTRO_installDir}/bin/mktsimple\" ${OPTIONS}" )
else
	STEPS=( "executeLogAndError \"${TTRO_installDir}/bin/mktsimple\" ${OPTIONS}" )
fi

STEPS+=( 'checkOutput' )

checkOutput() {
	case ${TTRO_variantCase} in
		help)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*The Make It Simple project wizard*';;
		typehelp)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Build one executable from all*' '*Build executable targets from each*';;
		invalidOption)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*ERROR: Invalid parameter*';;
		missingValue)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*ERROR: Missing value for parameter*';;
		*)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '* All done *';;
	esac
	return 0
}

case ${TTRO_variantCase} in
	*proj1)
		STEPS+=( checkOutput2 );;
esac

if [[ -n ${HELLO_WORLD} ]]; then
	STEPS+=(
		"cd ${PROJECT_DIR}"
		'make'
		"echoExecuteInterceptAndSuccess ./${BINDIR}${TARGET}"
	)
fi

checkOutput2() {
	case ${TTRO_variantCase} in
		otocppproj1)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44';;
		ipbcppproj1)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44';;
		opbcppproj1)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44';;
		opbcproj1)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CC = gcc'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CFLAGS = --std=c11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44';;
		opbproj1)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CC = gcc'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CFLAGS = --std=c11'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'
	esac
}
