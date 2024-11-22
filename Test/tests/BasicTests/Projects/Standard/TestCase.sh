#--variantList='default run debug runVerbose debugVerbose runAll debugAll runCleanAll debugCleanAll runClean debugClean runClean2 debugClean2 runInfo debugInfo helpGoal'

OPTIONS='CXXFLAGS=-std=c++11'
case ${TTRO_variantCase} in
	run*)
		OPTIONS+=' BUILD_MODE=run'
		BINDIR='run'
		BUILDDIR='run/build/src';;
	debug*)
		OPTIONS+=' BUILD_MODE=debug'
		BINDIR='debug'
		BUILDDIR='debug/build/src';;
	*)
		BINDIR='debug'
		BUILDDIR='debug/build/src';;
esac

VERBOSE=
case ${TTRO_variantCase} in
	*Verbose)
	VERBOSE='true';;
	*)
	OPTIONS+=" -s";;
esac

GOALS=
BUILD_FIRST=
IS_CLEAN=
IS_TOTAL_CLEAN=
NOBUILD=
HASCOMPDB=
HASCONFIGSTORE=
case ${TTRO_variantCase} in
	default|run|debug|runVerbose|debugVerbose)
		HASCOMPDB='true'
		HASCONFIGSTORE='true';;
	*CleanAll)
		GOALS='clean all'
		HASCOMPDB='true'
		HASCONFIGSTORE='true';;
	*Clean2)
		GOALS='purge'
		BUILD_FIRST='true'
		IS_CLEAN='true'
		IS_TOTAL_CLEAN='true'
		HASCOMPDB=''
		HASCONFIGSTORE='';;
	*All)
		GOALS='all'
		HASCOMPDB='true'
		HASCONFIGSTORE='true';;
	*Clean)
		GOALS='clean'
		BUILD_FIRST='true'
		IS_CLEAN='true'
		HASCOMPDB='true'
		HASCONFIGSTORE='true';;
	*Info)
		GOALS='show'
		NOBUILD='true'
		IS_CLEAN='true'
		IS_TOTAL_CLEAN='true'
		HASCOMPDB=''
		HASCONFIGSTORE='';;
	helpGoal)
		GOALS='help'
		NOBUILD='true'
		IS_CLEAN='true'
		IS_TOTAL_CLEAN='true'
		HASCOMPDB=''
		HASCONFIGSTORE='';;
	*)
		printErrorAndExit "Wrong case variant ${TTRO_variantCase}"
esac

MODULE1='m1.cpp'
MODULE2='m2.cc'
SRCDIR='src/'
if [[ ( "${TTRO_variantSuite}" = 'ProjectOutPlaceBuildC' ) || ( "${TTRO_variantSuite}" = 'ProjectOutPlaceBuild2') ]]; then
	MODULE2='m2.c'
fi
if [[ "${TTRO_variantSuite}" = 'ProjectOutPlaceBuildC' ]]; then
	MODULE1='m1.c'
fi
if [[ ( "${TTRO_variantSuite}" = 'ProjectInPlaceBuild' ) || ( "${TTRO_variantSuite}" = 'OneToOne') ]]; then
	BINDIR=.
	BUILDDIR=.
	SRCDIR=
fi

PREPS=(
	'cp -r ${TTRO_inputDirSuite}/../../${TTRO_variantSuite}TestProject/* .'
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y \"${TTRO_projectType}\" --noprompt"
)

STEPS=( 'echo ${TTRO_variantSuite} ${TTRO_variantCase}' )
# Make the project before cleanup tests
if [[ -n $BUILD_FIRST ]]; then
	STEPS+=( 'echoAndExecute make $OPTIONS all' )
	if [[ ${TTRO_variantSuite} = 'OneToOne' ]]; then
		STEPS+=(
			'echoAndExecute ./m1'
			'echoAndExecute ./m2'
		)
	else
		STEPS+=( 'echoAndExecute ${BINDIR}/${TTRO_variantCase}' )
	fi
fi
# The main test run
STEPS+=('executeLogAndSuccess make $OPTIONS $GOALS')
# Test for built results in case of cleanup test
if [[ -n $IS_CLEAN ]]; then
	if [[ ${TTRO_variantSuite} = 'OneToOne' ]]; then
		STEPS+=(
			'if [[ -e m1 ]]; then setFailure "File m1 exists!"; fi'
			'if [[ -e m2 ]]; then setFailure "File m2 exists!"; fi'
		)
	else
		STEPS+=( 'if [[ -e ${BINDIR}/${TTRO_variantCase} ]]; then setFailure "File ${BINDIR}/${TTRO_variantCase} exists!"; fi' )
	fi
fi
# Test the for .o and .dep files in bin dir in case of cleanup test
if [[ -n $IS_CLEAN ]]; then
	STEPS+=(
		'THEFILES=$(echo ${BUILDDIR}/*.o ${BUILDDIR}/*.dep)'
		'if [[ -n $THEFILES ]]; then setFailure "The directory has build artifacts: $THEFILES"; fi'
	)
fi

if [[ -n $IS_TOTAL_CLEAN ]]; then
	STEPS+=(
		'THEFILES=$(echo ${BUILDDIR}/*.mks.tmp)'
		'if [[ -n $THEFILES ]]; then setFailure "The directory has build artifacts: $THEFILES"; fi'
	)
fi
if [[ -n $HASCOMPDB ]]; then
	STEPS+=( 'if [[ -e compile_commands.json ]]; then : else setFailure "compile_commands.json not found!"; fi' )
else
	STEPS+=( 'if [[ -e compile_commands.json ]]; then setFailure "compile_commands.json exists!"; fi' )
fi
if [[ -n $HASCONFIGSTORE ]]; then
	STEPS+=( 'if [[ -e mks_last_config_store ]]; then : else setFailure "mks_last_config_store not found!"; fi' )
else
	STEPS+=( 'if [[ -e mks_last_config_store ]]; then setFailure "mks_last_config_store exists!"; fi' )
fi
# these files should never remain
STEPS+=(
	'THEFILES=$(echo ${SRCDIR}*.cpp.mks.tmp ${SRCDIR}*.cc.mks.tmp ${SRCDIR}*.c.mks.tmp ${SRCDIR}*.s.mks.tmp)'
	'if [[ -n $THEFILES ]]; then setFailure "The directory is not empty: $THEFILES"; fi'
	'if [[ -e .mks_temp_config_store ]]; then setFailure ".mks_temp_config_store exists!"; fi'
	)

# Test of all empty bin dirs in nobuild cases
if [[ -n $NOBUILD ]]; then
	STEPS+=( 'checkNoBuildOutput' )
# Execute the program in all build cases
else
	if [[ -z $IS_CLEAN ]]; then
		if [[ ${TTRO_variantSuite} = 'OneToOne' ]]; then
			STEPS+=(
				'echoAndExecute ./m1'
				'echoAndExecute ./m2'
			)
		else
			STEPS+=( 'echoAndExecute ${BINDIR}/${TTRO_variantCase}' )
		fi
	fi
	STEPS+=( 'checkBuildOutput' )
fi

checkBuildOutput() {
	if [[ -n $VERBOSE ]]; then
		if [[ ${TTRO_variantSuite} = 'OneToOne' ]]; then
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'Finished building: m1.cpp' \
				'Finished building: m2.cc'
		else
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				"Finished linking target:*${TTRO_variantCase}"
		fi
		if [[ -n $HASCOMPDB ]]; then
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Finished database compile_commands.json*'
		fi
	fi
	if [[ -n $VERBOSE && -z $NOBUILD ]]; then
		case ${TTRO_variantCase} in
			run*)   local CXXOPTIONTOFIND='-O2';;
			debug*) local CXXOPTIONTOFIND='-Og';;
		esac
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			"*${MODULE1}*${CXXOPTIONTOFIND}*" \
			"*${MODULE2}*${CXXOPTIONTOFIND}*"
	fi
	case ${TTRO_variantCase} in
		*Verbose)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Sources found :*${MODULE1}*${MODULE2}*"
			;;
	esac
}

checkNoBuildOutput() {
	case ${TTRO_variantCase} in
		*Info)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Sources found :*${MODULE1}*${MODULE2}*"
			;;
		helpGoal)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*This make script builds*' \
				'*-O\[TYPE\], --output-sync\[=TYPE\]  Synchronize output of parallel jobs by TYPE*';;
	esac
}