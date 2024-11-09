#--variantList="${TTRO_compilerVariants}"

if [[ ${TTRO_variantSuite} = 'default' ]]; then
	# Set the 'default' category for variant 'default'
	setCategory 'default'
else
	# All other variants get the category 'extended'
	setCategory 'extended'
	export CXX="${TTRO_variantSuite}"
	case "${TTRO_variantSuite}" in
		g++*) export CC="${TTRO_variantSuite/g++/gcc}";;
		clang*) export CC="${TTRO_variantSuite/clang++/clang}";;
	esac
fi

if isExisting 'CXX'; then
	suiteCompiler="$CXX"
else
	suiteCompiler='g++'
fi

if isExisting 'CC'; then
	suiteCCompiler="$CC"
else
	suiteCCompiler='cc'
fi

if ! ${suiteCompiler} --version; then
  setSkip "No such compiler installed: ${suiteCompiler}"
fi
if ! ${suiteCCompiler} --version; then
  setSkip "No such compiler installed: ${suiteCCompiler}"
fi

PREPS=(
	'printInfo "Testing with MakeItSimple installation in ${TTRO_installDir}"'
	'${suiteCompiler} --version'
	'prepareWarnFile2'
)

prepareWarnFile2() {
	if [ "${TTRO_variantSuite}" != 'default' ]; then
		local compiler_warnfile=${TTRO_variantSuite/clang++/clang}
		export MAKEFILE_WARN="${TTRO_installDir}/mktsimple/warnings.${compiler_warnfile}.mk"
	fi
}

prepareWarnFile() {
	local versionstring=$(${suiteCompiler} --version)
	if [[ $versionstring =~ g\+\+.*[[:blank:]]+([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+).* ]]; then
		printInfo "g++ compiler major version ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
		if [[ ${BASH_REMATCH[1]} -eq 7 ]]; then
			setVar 'TTRO_warnFile' "${TTRO_installDir}/mktsimple/warnings.g++7.mk"
		elif [[ ${BASH_REMATCH[1]} -eq 11 ]]; then
			setVar 'TTRO_warnFile' "${TTRO_installDir}/mktsimple/warnings.g++11.mk"
		else
			setVar 'TTRO_warnFile' ""
		fi
	else
		printInfo "no g++ compiler"
		setVar 'TTRO_warnFile' ""
	fi
}