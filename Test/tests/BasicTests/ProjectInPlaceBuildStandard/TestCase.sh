#--variantList='default run debug runVerbose debugVerbose runAll debugAll runCleanAll debugCleanAll runClean debugClean runInfo debugInfo helpGoal Clean_All'

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
HASCOMPDB='true'
case ${TTRO_variantCase} in
	*CleanAll)
		GOALS='clean all';;
	*Clean_All)
		GOALS='distclean'
		CLEANUP='true'
		HASCOMPDB='';;
	*All)
		GOALS='all';;
	*Clean)
		GOALS=clean
		CLEANUP='true';; # db exists from previous make all
	*Info)
		GOALS=info
		NOBUILD='true'
		HASCOMPDB='';;
	helpGoal)
		GOALS=help
		NOBUILD='true'
		HASCOMPDB='';;
esac

PREPS=(
	'cp ${TTRO_inputDirSuite}/../ProjectInPlaceBuildTestProject/* .'
	'cp "${TTRO_installDir}/ProjectInPlaceBuild/Makefile" .'
)

# Make the project before cleanup tests
if [[ -n $CLEANUP ]]; then
	STEPS=(
		'echoAndExecute make $OPTIONS all'
		'echoAndExecute ./${TTRO_variantCase}'
	)
fi
# The main test run
STEPS+=('executeLogAndSuccess make $OPTIONS $GOALS')
# Test the for empty bin dir in case of cleanup test
if [[ -n $CLEANUP ]]; then
	STEPS+=(
		'if [[ -e ${TTRO_variantCase} ]]; then setFailure "File ${TTRO_variantCase} exists!"; fi'
		'THEFILES=$(echo *.o *.d)'
		'if [[ -n $THEFILES ]]; then setFailure "The directory is not empty: $THEFILES"; fi'
	)
# Test of all empty bin dirs in nobuild cases
elif [[ -n $NOBUILD ]]; then
	STEPS+=(
		'if [[ -e ${TTRO_variantCase} ]]; then setFailure "File ${TTRO_variantCase} exists!"; fi'
		'THEFILES=$(echo *.o *.d)'
		'if [[ -n $THEFILES ]]; then setFailure "The directory is not empty: $THEFILES"; fi'
		'checkNoBuildOutput'
	)
# Execute the program in all build cases
else
	STEPS+=(
		'echoAndExecute ./${TTRO_variantCase}'
		'checkBuildOutput'
	)
fi

if [[ -n $HASCOMPDB ]]; then
	STEPS+=(
	'if [[ -e compile_commands.json ]]; then : else setFailure "compile_commands.json not found!"; fi'
	)
else
	STEPS+=(
	'if [[ -e compile_commands.json ]]; then setFailure "compile_commands.json exists!"; fi'
	)
fi

checkBuildOutput() {
	if [[ -n $VERBOSE ]]; then
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			'Finished building: m1.cpp' \
			'Finished building: m2.cc' \
			"Finished linking target: ${TTRO_variantCase}"
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
			"*m1.cpp*${CXXOPTIONTOFIND}*" \
			"*m2.cc*${CXXOPTIONTOFIND}*" \
			"*-o*${TTRO_variantCase}*"
	fi
	case ${TTRO_variantCase} in
		*Verbose)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${TTRO_variantCase}'*" \
					'Sources found : m1.cpp m2.cc'
			;;
	esac
}

checkNoBuildOutput() {
	case ${TTRO_variantCase} in
		*Info)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${TTRO_variantCase}'*" \
					'Sources found : m1.cpp m2.cc'
			;;
		helpGoal)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					'*This make script builds one executable*' \
					'*-O\[TYPE\], --output-sync\[=TYPE\]  Synchronize output of parallel jobs by TYPE*';;
	esac
}