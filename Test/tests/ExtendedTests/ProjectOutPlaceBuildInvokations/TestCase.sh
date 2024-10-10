#--variantList='default invalidWarn invalidBuildMode cxxFlags cppFlages incsysdir cleanall cleanallall cleanallsilent cleanallallsilent'

OPTIONS=
EXPECT_FAILURE=
BINDIR=debug
case ${TTRO_variantCase} in
	default)
		: ;;
	invalidWarn)
		EXPECT_FAILURE='true'
		OPTIONS='WARN_LEVEL=4';;
	invalidBuildMode)
		EXPECT_FAILURE='true'
		OPTIONS='BUILD_MODE=4';;
	cxxFlags)
		OPTIONS='WARN_LEVEL=0 CXXFLAGS=-Wextra';;
	cppFlages)
		OPTIONS='WARN_LEVEL=0 CPPFLAGS=-DMY_MACRO=11';;
	incsysdir)
		OPTIONS='WARN_LEVEL=2 INCSYSDIRS=/dir1/dir2';;
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

PREPS=(
	'cp -r ${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/include .'
	'cp -r ${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/src .'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild/Makefile" .'
)

# The main test run
STEPS=(
	'[[ -n ${EXPECT_FAILURE} ]] || executeLogAndSuccess make $OPTIONS'
	'[[ -z ${EXPECT_FAILURE} ]] || executeLogAndError make $OPTIONS'
	'[[ -n ${EXPECT_FAILURE} ]] || echoAndExecute "${BINDIR}/${TTRO_variantCase}"'
	'checkBuildOutput'
)

checkBuildOutput() {
	case ${TTRO_variantCase} in
		default)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'Finished building: src/m1.cpp' \
				'Finished building: src/m2.cc' \
				"Finished linking target: ${BINDIR}/${TTRO_variantCase}";;
		invalidWarn)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Invalid WARN_LEVEL*';;
		invalidBuildMode)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Build mode 4 is not supported*';;
		cxxFlags)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*src/m1.cpp*-Wextra*-ftabstop=4*-MMD*' \
				'*src/m2.cc*-Wextra*-ftabstop=4*-MMD*' \
				"*m1.o*m2.o*-o*${BINDIR}/${TTRO_variantCase}*";;
		cppFlages)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*src/m1.cpp*-DMY_MACRO=11*' \
				'*src/m2.cc*-DMY_MACRO=11*' \
				"*m1.o*m2.o*-o*${BINDIR}/${TTRO_variantCase}*";;
		incsysdir)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*src/m1.cpp*-I/dir1/dir2*' \
				'*src/m2.cc*-I/dir1/dir2*' \
				"*m1.o*m2.o*-o*${BINDIR}/${TTRO_variantCase}*";;
		cleanallall*)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*distclean must be the only goal!*';;
		cleanall*)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Cleanup and production is not allowed with parallel make enabled!*';;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
}
