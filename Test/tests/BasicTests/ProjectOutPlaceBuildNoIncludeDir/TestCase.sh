#--variantList='default info help clean all'

BINDIR='debug'
OPTIONS=''

GOALS=
CLEANUP=
NOBUILD=
VERBOSE=
case ${TTRO_variantCase} in
	clean)
		GOALS=clean
		CLEANUP='true';;
	info)
		GOALS=info
		NOBUILD='true';;
	help)
		GOALS=help
		NOBUILD='true';;
	all)
		GOALS=all
		VERBOSE='true';;
esac

PREPS=(
	'copyOnly'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild/Makefile" .'
)

# Make the project before cleanup tests
if [[ -n $CLEANUP ]]; then
	STEPS=(
		'echoAndExecute make all'
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
		local CXXOPTIONTOFIND='-Og'
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			"*${CXXOPTIONTOFIND}*src/m1.cpp*" \
			"*${CXXOPTIONTOFIND}*src/m2.cc*" \
			"*-o*${BINDIR}/${TTRO_variantCase}*"

		linewisePatternMatchInterceptAndError "${TT_evaluationFile}" 'true' '*-iquoteinclude*'
	fi
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