#--variantList='help typehelp invalidOption missingValue'

OPTIONS=
EXPECT_FAILURE=
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
	*)
		printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
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
	esac
	return 0
}
