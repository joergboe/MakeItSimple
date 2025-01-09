#--variantList='default project1'

OPTIONS=
PROJECT_DIR='.'
BINDIR=
TARGET="${TTRO_variantCase}"
COPY_WARN=
case ${TTRO_variantSuite} in
	otocpp)
		OPTIONS='--type otocpp --no-prompt'
		TARGET='hello';;
	ipbcpp)
		OPTIONS='--type ipbcpp --noprompt';;
	opbcpp)
		OPTIONS='--type opbcpp -n'
		BINDIR='debug/';;
	opbc)
		OPTIONS='--type opbc --noprompt'
		BINDIR='debug/';;
	opb)
		OPTIONS='--type opb --noprompt'
		BINDIR='debug/';;
	*)
		printErrorAndExit "Invalid suite variant ${TTRO_variantSuite}";;
esac

case ${TTRO_variantCase} in
	default)
		OPTIONS+=' --hello-world';;
	project1)
		if [[ ${TTRO_variantSuite} != otocpp ]]; then
			OPTIONS+=' --target-name prog1'
			TARGET='prog1'
		fi
		if [[ ${TTRO_variantSuite} == opb* ]]; then
			OPTIONS+=' --src-dir so1 --src-dir so2 --inc incl'
		fi
		OPTIONS+=' --hello-world --project-dir project1 --incsysdirs isys44 --cc gcc --cxx g++ --cppflags -DMYHELLO=xxxxx'
		OPTIONS+=' --cxxflags --std=c++11 --cflags --std=c11 --ldflags -Ldd44 --ldlibs -lrt --copy-warn'
		PROJECT_DIR='project1'
		COPY_WARN='true';;
esac

STEPS=(
	"executeLogAndSuccess \"${TTRO_installDir}/bin/mktsimple\" ${OPTIONS}"
	'checkOutput'
)

if [[ ${TTRO_variantCase} == 'project1' ]]; then
	STEPS+=( checkProjectMk )
fi
if [[ ${TTRO_variantCase} == 'default' ]]; then
	STEPS+=( checkProjectMk0 )
fi

if [[ -n ${COPY_WARN} ]]; then
	STEPS+=( "checkAllFilesExist \"${PROJECT_DIR}/mktsimple\" 'warnings.cc-12.mk warnings.cc-7.mk warnings.clang-17.mk warnings.g++-12.mk warnings.g++-7.mk warnings.gcc-14.mk warnings.cc-13.mk warnings.clang-13.mk warnings.clang-18.mk warnings.g++-13.mk warnings.gcc-12.mk warnings.gcc-7.mk warnings.cc-14.mk warnings.clang-14.mk warnings.clang-19.mk warnings.g++-14.mk warnings.gcc-13.mk'" )
else
	STEPS+=( "if [[ -d \"${PROJECT_DIR}/mktsimple\" ]]; then setFailure 'Makefile directory exists!'; fi" )
fi

STEPS+=(
	"cd ${PROJECT_DIR}"
	'echoExecuteInterceptAndSuccess make'
	"echoExecuteInterceptAndSuccess ./${BINDIR}${TARGET}"
)

checkOutput() {
	linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '* All done *'
	return 0
}

checkProjectMk0() {
	case ${TTRO_variantSuite} in
		otocpp)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true' 'project_type = otocpp';;
		ipbcpp)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true' 'project_type = ipbcpp';;
		opbcpp)
			if [[ -f "${PROJECT_DIR}/project.mk" ]]; then
				setFailure "project.mk exists"
			fi;;
		opbc)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true' 'project_type = opbc';;
		opb)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true' 'project_type = opb';;
	*)
		printErrorAndExit "Invalid suite variant ${TTRO_variantSuite}";;
	esac
}

checkProjectMk() {
	case ${TTRO_variantSuite} in
		otocpp)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt'\
			'project_type = otocpp'\
			'copy_warnings = true';;
		ipbcpp)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt'\
			'project_type = ipbcpp'\
			'copy_warnings = true';;
		opbcpp)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt'\
			'copy_warnings = true';;
		opbc)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CC = gcc'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CFLAGS = --std=c11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt'\
			'project_type = opbc'\
			'copy_warnings = true';;
		opb)
			linewisePatternMatchInterceptAndSuccess "${PROJECT_DIR}/project.mk" 'true'\
			'TARGET = prog1'\
			'SRCDIRS = so1 so2'\
			'INCDIRS = incl'\
			'CC = gcc'\
			'CPPFLAGS = -DMYHELLO=xxxxx'\
			'CFLAGS = --std=c11'\
			'CXXFLAGS = --std=c++11'\
			'INCSYSDIRS = isys44'\
			'LDFLAGS = -Ldd44'\
			'LDLIBS = -lrt'\
			'project_type = opb'\
			'copy_warnings = true';;
	*)
		printErrorAndExit "Invalid suite variant ${TTRO_variantSuite}";;
	esac
}
