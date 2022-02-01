#--variantList="${TTRO_compilerVariants}"

echo "Testing with MakeItSimple installation in ${TTRO_installDir}"
if [[ ${TTRO_variantSuite} != 'default' ]]; then
	export CXX="${TTRO_variantSuite}"
fi

if isExisiting 'CXX'; then
	suiteCompiler="$CXX"
else
	suiteCompiler='g++'
fi
${suiteCompiler} --version
