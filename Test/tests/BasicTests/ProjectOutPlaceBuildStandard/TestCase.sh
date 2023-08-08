#--variantList='default run debug runVerbose debugVerbose runAll debugAll runCleanAll debugCleanAll runClean debugClean runClean2 debugClean2 runInfo debugInfo help'

OPTIONS='CXXFLAGS=-std=c++11'
case ${TTRO_variantCase} in
	default)
		BINDIR='debug';;
	run*)
		OPTIONS+=' BUILD_MODE=run'
		BINDIR='run';;
	debug*)
		OPTIONS+=' BUILD_MODE=debug'
		BINDIR='debug';;
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
CLEANUP2=
NOBUILD=
case ${TTRO_variantCase} in
	*CleanAll)
		GOALS='clean all';;
	*All)
		GOALS='all';;
	*Clean)
		GOALS=clean
		CLEANUP='true';;
	*Clean2)
		GOALS=clean_all
		CLEANUP2='true';;
	*Info)
		GOALS=info
		NOBUILD='true';;
	help)
		GOALS=help
		NOBUILD='true';;
esac

PREPS=(
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/include" .'
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/src" .'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild/Makefile" .'
)

# Make the project before cleanup tests
if [[ -n $CLEANUP ]]; then
	STEPS=(
		'echoAndExecute make $OPTIONS all'
		'echoAndExecute ${BINDIR}/${TTRO_variantCase}'
	)
fi
# The main test run
STEPS+=('executeLogAndSuccess make $OPTIONS $GOALS')
# Test the for empty bin dir in case of cleanup test
if [[ -n $CLEANUP ]]; then
	STEPS+=(
		'THEFILES=$(ls ${BINDIR})'
		'if [[ -n $THEFILES ]]; then setFailure "The directory $BINDIR is not empty: $THEFILES"; fi'
	)
# Test the for deleted build dir
elif [[ -n $CLEANUP2 ]]; then
	STEPS+=(
		'if [[ -e run ]]; then setFailure "The directory/file run exists!"; fi'
		'if [[ -e debug ]]; then setFailure "The directory/file debug exists!"; fi'
	)
# Test of all empty bin dirs in nobuild cases
elif [[ -n $NOBUILD ]]; then
	STEPS+=(
		'if [[ -e run ]]; then setFailure "The directory/file run exists!"; fi'
		'if [[ -e debug ]]; then setFailure "The directory/file debug exists!"; fi'
		'checkNoBuildOutput'
	)
# Execute the program in all build cases
else
	STEPS+=(
		'echoAndExecute ${BINDIR}/${TTRO_variantCase}'
		'checkBuildOutput'
	)
fi

checkBuildOutput() {
	linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		'Finished building: src/m1.cpp' \
		'Finished building: src/m2.cc' \
		"Finished linking target: ${BINDIR}/${TTRO_variantCase}"

	if [[ -n $VERBOSE && -z $NOBUILD ]]; then
		case ${TTRO_variantCase} in
			run*)   local CXXOPTIONTOFIND='-O2';;
			debug*) local CXXOPTIONTOFIND='-Og';;
		esac
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			"*${CXXOPTIONTOFIND}*\"src/m1.cpp\"" \
			"*${CXXOPTIONTOFIND}*\"src/m2.cc\"" \
			"*-o \"${BINDIR}/${TTRO_variantCase}\""
	fi
	case ${TTRO_variantCase} in
		*Verbose)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${BINDIR}/${TTRO_variantCase}'*" \
					'Sources found : src/m1.cpp src/m2.cc'
			;;
	esac

}

checkNoBuildOutput() {
	case ${TTRO_variantCase} in
		*Info)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${BINDIR}/${TTRO_variantCase}'*" \
					'Sources found : src/m1.cpp src/m2.cc'
			;;
		help)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*This make script builds one executable*';;
	esac
}