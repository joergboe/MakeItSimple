#--variantList='run debug runClean debugClean runInfo debugInfo runTarget debugTarget runTargetClean debugTargetClean'

OPTIONS=''
case ${TTRO_variantCase} in
	run*)
		OPTIONS+=' BUILD_MODE=run'
		BINDIR='run';;
	debug*)
		OPTIONS+=' BUILD_MODE=debug'
		BINDIR='debug';;
esac

BUILDDIR="${BINDIR}/build"
GOALS=
CLEANUP=
NOBUILD=
case ${TTRO_variantCase} in
	*Clean)
		GOALS=clean
		CLEANUP='true';;
	*Info)
		GOALS='show'
		NOBUILD='true';;
esac

CHANGETARGET=
TARGETNAME="${TTRO_variantCase}"
case ${TTRO_variantCase} in
	*Target*)
		CHANGETARGET='true'
		TARGETNAME='program';;
esac

PREPS=(
	'copyOnly'
	"\"${TTRO_installDir}/bin/mktsimple\" -d . -t opbcpp --noprompt"
	'[[ -z ${CHANGETARGET} ]] || echo "TARGET := program" >> project.mk'
)

# Make the project before cleanup tests
if [[ -n $CLEANUP ]]; then
	STEPS=(
		'echoAndExecute make $OPTIONS all'
		'echoAndExecute ${BINDIR}/${TARGETNAME}'
	)
fi
# The main test run
STEPS+=('executeLogAndSuccess make $OPTIONS $GOALS')
# Test the for empty bin dir in case of cleanup test
if [[ -n $CLEANUP ]]; then
	STEPS+=(
		'THEFILES=$(echo ${BINDIR}/program* ${BINDIR}/${TTRO_variantCase}* ${BUILDDIR}/*.o ${BUILDDIR}/*.dep)'
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
		'echoAndExecute ${BINDIR}/${TARGETNAME}'
		'checkBuildOutput'
	)
fi

checkBuildOutput() {
	linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		'Finished building: ./m1.cpp' \
		'Finished building: mysources/m2.cc' \
		"Finished linking target: ${BINDIR}/${TARGETNAME}"
}

checkNoBuildOutput() {
	case ${TTRO_variantCase} in
		*Info)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
					"Build target '${BINDIR}/${TARGETNAME}'*" \
					'Sources found :*./m1.cpp*' \
					'Sources found :*mysources/m2.cc*'
			;;
	esac
}