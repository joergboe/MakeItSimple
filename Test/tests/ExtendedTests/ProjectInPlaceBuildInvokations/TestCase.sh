#--variantList='default invalidWarn invalidBuildMode cxxFlags cppFlages incsysdir'

OPTIONS=
EXPECT_FAILURE=
case ${TTRO_variantCase} in
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
esac

PREPS=(
	'cp ${TTRO_inputDirSuite}/../ProjectInPlaceBuildTestProject/* .'
	'cp "${TTRO_installDir}/ProjectInPlaceBuild/Makefile" .'
)

# The main test run
STEPS=(
	'[[ -n ${EXPECT_FAILURE} ]] || executeLogAndSuccess make $OPTIONS'
	'[[ -z ${EXPECT_FAILURE} ]] || executeLogAndError make $OPTIONS'
	'[[ -n ${EXPECT_FAILURE} ]] || echoAndExecute "./${TTRO_variantCase}"'
	'checkBuildOutput'
)

checkBuildOutput() {
	case ${TTRO_variantCase} in
		default)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'Finished building: m1.cpp'\
				'Finished building: m2.cc'\
				"Finished linking target: ${TTRO_variantCase}";;
		invalidWarn)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Invalid WARN_LEVEL*';;
		invalidBuildMode)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' '*Build mode 4 is not supported*';;
		cxxFlags)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*-ftabstop=4 -Wextra -MMD*"m1.cpp"'\
				'*-ftabstop=4 -Wextra -MMD*"m2.cc"'\
				"*-ftabstop=4 -Wextra*-o \"${TTRO_variantCase}\"";;
		cppFlages)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*-DMY_MACRO=11*"m1.cpp"'\
				'*-DMY_MACRO=11*"m2.cc"'\
				"*-ftabstop=4*-o \"${TTRO_variantCase}\"";;
		incsysdir)
			linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
				'*-I/dir1/dir2*"m1.cpp"'\
				'*-I/dir1/dir2*"m2.cc"'\
				"*-ftabstop=4*-o \"${TTRO_variantCase}\"";;
	esac
}
