#--variantList="${TTRO_compilerVariants}"

if [[ ${TTRO_variantSuite} = 'default' ]]; then
	# Set the 'default' category for variant 'default'
	setCategory 'default'
else
	# All other variants get the category 'extended'
	setCategory 'extended'
	export CXX="${TTRO_variantSuite}"
fi

if isExisting 'CXX'; then
	suiteCompiler="$CXX"
else
	suiteCompiler='g++'
fi

PREPS=(
	'echo "Testing with MakeItSimple installation in ${TTRO_installDir}"'
	'${suiteCompiler} --version'
)
