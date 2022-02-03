#--variantList='default invalidWarn invalidBuildMode cxxFlags cppFlages incsysdir'

OPTIONS=
EXPECT_FAILURE=
BINDIR=debug
case ${TTRO_variantCase} in
	invalidWarn)
		EXPECT_FAILURE='true'
		OPTIONS='WARN_LEVEL=4';;
	invalidBuildMode)
		EXPECT_FAILURE='true'
		OPTIONS='BUILD_MODE=4';;
	cxxFlags)
		OPTIONS='WARN_LEVEL=0 CXXFLAGS=-Wextra VERBOSE=1';;
	cppFlages)
		OPTIONS='WARN_LEVEL=0 CPPFLAGS=-DMY_MACRO=11 VERBOSE=true';;
	incsysdir)
		OPTIONS='WARN_LEVEL=2 INCSYSDIRS=/dir1/dir2 VERBOSE=1';;
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
				'*-ftabstop=4 -Wextra -MMD*"src/m1.cpp"' \
				'*-ftabstop=4 -Wextra -MMD*"src/m2.cc"' \
				"*-ftabstop=4 -Wextra*-o \"${BINDIR}/${TTRO_variantCase}\"";;
		cppFlages)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*-DMY_MACRO=11*"src/m1.cpp"' \
				'*-DMY_MACRO=11*"src/m2.cc"' \
				"*-ftabstop=4*-o \"${BINDIR}/${TTRO_variantCase}\"";;
		incsysdir)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*-I/dir1/dir2*"src/m1.cpp"' \
				'*-I/dir1/dir2*"src/m2.cc"' \
				"*-ftabstop=4*-o \"${BINDIR}/${TTRO_variantCase}\"";;
	esac
}
