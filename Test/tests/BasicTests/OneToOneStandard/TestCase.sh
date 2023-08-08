#--variantList='default run debug runVerbose debugVerbose runAll debugAll runCleanAll debugCleanAll runClean debugClean runInfo debugInfo helpGoal'

OPTIONS='CXXFLAGS=-std=c++11'
case ${TTRO_variantCase} in
	run*)
		OPTIONS+=' BUILD_MODE=run';;
	debug*)
		OPTIONS+=' BUILD_MODE=debug';;
esac

VERBOSE=
case ${TTRO_variantCase} in
	*Verbose)
	VERBOSE='true';;
	*)
	OPTIONS+=" -s";;
esac

GOALS=
CLEANUP=
NOBUILD=
case ${TTRO_variantCase} in
	*CleanAll)
		GOALS='clean all';;
	*All)
		GOALS='all';;
	*Clean)
		GOALS=clean
		CLEANUP='true';;
	*Info)
		GOALS=info
		NOBUILD='true';;
	helpGoal)
		GOALS=help
		NOBUILD='true';;
esac

PREPS=(
	'cp ${TTRO_inputDirSuite}/../OneToOneTestProject/* .'
	'cp "${TTRO_installDir}/OneToOne/Makefile" .'
)

# Make the project before cleanup tests
if [[ -n $CLEANUP ]]; then
	STEPS=(
		'echoAndExecute make $OPTIONS all'
		'echoAndExecute ./m1'
		'echoAndExecute ./m2'
	)
fi
# The main test run
STEPS+=('executeLogAndSuccess make $OPTIONS $GOALS')
# Test the for empty bin dir in case of cleanup test
if [[ -n $CLEANUP ]]; then
	STEPS+=(
		'if [[ -e m1 ]]; then setFailure "File m1 exists!"; fi'
		'if [[ -e m2 ]]; then setFailure "File m2 exists!"; fi'
		'THEFILES=$(echo *.o *.d)'
		'if [[ -n $THEFILES ]]; then setFailure "The directory is not empty: $THEFILES"; fi'
	)
# Test of all empty bin dirs in nobuild cases
elif [[ -n $NOBUILD ]]; then
	STEPS+=(
		'if [[ -e m1 ]]; then setFailure "File m1 exists!"; fi'
		'if [[ -e m2 ]]; then setFailure "File m2 exists!"; fi'
		'THEFILES=$(echo *.o *.d)'
		'if [[ -n $THEFILES ]]; then setFailure "The directory is not empty: $THEFILES"; fi'
		'checkNoBuildOutput'
	)
# Execute the program in all build cases
else
	STEPS+=(
		'echoAndExecute ./m1'
		'echoAndExecute ./m2'
		'checkBuildOutput'
	)
fi

checkBuildOutput() {
	linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		'Finished building: m1.cpp' \
		'Finished building: m2.cc'

	if [[ -n $VERBOSE && -z $NOBUILD ]]; then
		case ${TTRO_variantCase} in
			run*)   local CXXOPTIONTOFIND='-O2';;
			debug*) local CXXOPTIONTOFIND='-Og';;
		esac
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			"*${CXXOPTIONTOFIND}*\"m1.cpp\"" \
			"*${CXXOPTIONTOFIND}*\"m2.cc\""
	fi
	case ${TTRO_variantCase} in
		*Verbose)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					'Sources found : m1.cpp m2.cc'
			;;
	esac

}

checkNoBuildOutput() {
	case ${TTRO_variantCase} in
		*Info)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					'Sources found : m1.cpp m2.cc'
			;;
		helpGoal)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*This make script builds executables from each*';;
	esac
}