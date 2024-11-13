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
	'prepareWarnFile "${suiteCompiler}" "${suiteCCompiler}"'
	'prepareWarnFile2'
)

prepareWarnFile2() {
	if [ "${TTRO_variantSuite}" != 'default' ]; then
		local compiler_warnfile=${TTRO_variantSuite/clang++/clang}
		export MAKEFILE_WARN="${TTRO_installDir}/mktsimple/warnings.${compiler_warnfile}.mk"
		local c_compiler_warnfile=${MAKEFILE_WARN/g++/gcc}
		export MAKEFILE_WARN_C="${c_compiler_warnfile}"
	fi
	if ! declare -p MAKEFILE_WARN; then
		echo "MAKEFILE_WARN is not defined!"
	fi
	if ! declare -p MAKEFILE_WARN_C; then
		echo "MAKEFILE_WARN_C is not defined!"
	fi
}

# args $1 c++ compiler, $2 c compiler
prepareWarnFile() {
	local versionstring=$($1 --version)
	if [[ $versionstring =~ (g\+\+|clang).*[[:blank:]]+([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+).* ]]; then
		printInfo "c++ compiler major version ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]}"
		setVar 'TTRO_warnFile' "${TTRO_installDir}/mktsimple/warnings.${BASH_REMATCH[1]}-${BASH_REMATCH[2]}.mk"
	else
		printErrorAndExit "unknown c++ compiler: ${versionstring}"
	fi
	local versionstring=$($2 --version)
	if [[ $versionstring =~ (cc|gcc|clang).*[[:blank:]]+([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+).* ]]; then
		printInfo "C compiler major version ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]}"
		local comp_name="${BASH_REMATCH[1]}"
		setVar 'TTRO_warnFileC' "${TTRO_installDir}/mktsimple/warnings.${BASH_REMATCH[1]}-${BASH_REMATCH[2]}.mk"
	else
		printErrorAndExit "unknown C compiler: ${versionstring}"
	fi
}