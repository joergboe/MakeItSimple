#--variantList='default invalidWarn invalidBuildMode cxxFlags cppFlages incsysdir cleanall cleanallall cleanallsilent cleanallallsilent'

OPTIONS=
EXPECT_FAILURE=
EXPECT_CONFIG_STORE=
EXPECT_COMPILE_DB=
case ${TTRO_variantCase} in
	default)
		EXPECT_CONFIG_STORE='true'
		EXPECT_COMPILE_DB='true';;
	invalidWarn)
		EXPECT_FAILURE='true'
		OPTIONS='WARN_LEVEL=6';;
	invalidBuildMode)
		EXPECT_FAILURE='true'
		OPTIONS='BUILD_MODE=4';;
	cxxFlags)
		OPTIONS='WARN_LEVEL=0 CXXFLAGS=-Wextra CFLAGS=-Wextra'
		EXPECT_CONFIG_STORE='true'
		EXPECT_COMPILE_DB='true';;
	cppFlages)
		OPTIONS='WARN_LEVEL=0 CPPFLAGS=-DMY_MACRO=11'
		EXPECT_CONFIG_STORE='true'
		EXPECT_COMPILE_DB='true';;
	incsysdir)
		OPTIONS='WARN_LEVEL=2 INCSYSDIRS=/dir1/dir2'
		EXPECT_CONFIG_STORE='true'
		EXPECT_COMPILE_DB='true';;
	cleanallall)
		OPTIONS='WARN_LEVEL=2 distclean m1'
		EXPECT_FAILURE='true';;
	cleanallallsilent)
		OPTIONS='WARN_LEVEL=2 -s distclean m1'
		EXPECT_FAILURE='true';;
	cleanall)
		OPTIONS='WARN_LEVEL=2 -j clean all'
		EXPECT_FAILURE='true';;
	cleanallsilent)
		OPTIONS='WARN_LEVEL=2 -j --silent clean all'
		EXPECT_FAILURE='true';;
	*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
esac

BINDIR=.
if [[ "${TTRO_variantSuite}" == ProjectOut* ]]; then
	BINDIR=debug
fi
PREPS=(
	'cp -r ${TTRO_inputDirSuite}/../../${TTRO_variantSuite}TestProject/* .'
	'cp "${TTRO_installDir}/${TTRO_variantSuite}/Makefile" .'
)

# The main test run
STEPS=(
	'[[ -n ${EXPECT_FAILURE} ]] || executeLogAndSuccess make $OPTIONS'
	'[[ -z ${EXPECT_FAILURE} ]] || executeLogAndError make $OPTIONS'
)
if [[ "${TTRO_variantSuite}" = 'OneToOne' ]]; then
	STEPS+=(
		'[[ -n ${EXPECT_FAILURE} ]] || echoAndExecute ./m1'
		'[[ -n ${EXPECT_FAILURE} ]] || echoAndExecute ./m2'
	)
else
	STEPS+=( '[[ -n ${EXPECT_FAILURE} ]] || echoAndExecute "${BINDIR}/${TTRO_variantCase}"')
fi
STEPS+=('checkBuildOutput0' 'checkBuildOutput' 'checkBuildOutput2')

checkBuildOutput0() {
	case ${TTRO_variantCase} in
		default|cxxFlags|cppFlages|incsysdir)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'Finished building: *m1.c*' \
				'Finished building: *m2.c*'
			if [[ "${TTRO_variantSuite}" != 'OneToOne' ]]; then
				linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' "*Finished linking target: *${TTRO_variantCase}*"
			fi;;
	esac
}
checkBuildOutput() {
	case ${TTRO_variantCase} in
		default)
			: ;;
		invalidWarn)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Invalid WARN_LEVEL*';;
		invalidBuildMode)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Build mode 4 is not supported*';;
		cxxFlags)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*m1.c*-Wextra*-ftabstop=4*-MMD*' \
				'*m2.c*-Wextra*-ftabstop=4*-MMD*';;
		cppFlages)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*m1.c*-DMY_MACRO=11*' \
				'*m2.c*-DMY_MACRO=11*';;
		incsysdir)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*m1.c*-I/dir1/dir2*' \
				'*m2.c*-I/dir1/dir2*';;
		cleanallall*)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*distclean must be the only goal!*';;
		cleanall*)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Cleanup and production is not allowed with parallel make enabled!*';;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
}

checkBuildOutput2() {
	if [[ -n $EXPECT_CONFIG_STORE ]]; then
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Configuration file mks_last_config_store written*'
	else
		linewisePatternMatchInterceptAndError "${TT_evaluationFile}" 'false' '*Configuration file mks_last_config_store written*'
	fi
	if [[ -n $EXPECT_COMPILE_DB ]]; then
		linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
			'*Finished database fragment *m1*.mks.tmp*' \
			'*Finished database fragment *m2*.mks.tmp*' \
			'*Finished database compile_commands.json*'
	else
		linewisePatternMatchInterceptAndError "${TT_evaluationFile}" 'false' \
			'*Finished database fragment *m1*.mks.tmp*' \
			'*Finished database fragment *m2*.mks.tmp*' \
			'*Finished database compile_commands.json*'
	fi
}