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
HASCOMPDB='true'
case ${TTRO_variantCase} in
	*CleanAll)
		GOALS='clean all';;
	*All)
		GOALS='all';;
	*Clean)
		GOALS=clean
		CLEANUP='true';;
	*Clean2)
		GOALS=distclean
		CLEANUP2='true'
		HASCOMPDB='';;
	*Info)
		GOALS='show'
		NOBUILD='true'
		HASCOMPDB='';;
	help)
		GOALS=help
		NOBUILD='true'
		HASCOMPDB='';;
esac

PREPS=(
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuild2TestProject/include" .'
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuild2TestProject/src" .'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild2/Makefile" .'
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
	if [[ -n $VERBOSE ]]; then
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			'Finished building: src/m1.cpp' \
			'Finished building: src/m2.c' \
			'Finished building: src/hello.s' \
			"Finished linking target: ${BINDIR}/${TTRO_variantCase}"
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
			"*src/m1.cpp*${CXXOPTIONTOFIND}*" \
			"*src/m2.c*${CXXOPTIONTOFIND}*" \
			"*-o*${BINDIR}/${TTRO_variantCase}*"
	fi
	case ${TTRO_variantCase} in
		*Verbose)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${BINDIR}/${TTRO_variantCase}'*" \
					'Sources found : src/m1.cpp* src/m2.c src/hello.s'
			;;
	esac
}

checkNoBuildOutput() {
	case ${TTRO_variantCase} in
		*Info)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${BINDIR}/${TTRO_variantCase}'*" \
					'Sources found : src/m1.cpp* src/m2.c src/hello.s'
			;;
		help)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			'*This make script builds one executable*' \
			'*-O\[TYPE\], --output-sync\[=TYPE\]  Synchronize output of parallel jobs by TYPE*';;
	esac
}