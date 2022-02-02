#--variantList='check default warn0 warn1 warn2 warn3 info help'

OPTIONS='VERBOSE=true'
BINDIR='debug'
GOALS=
NOBUILD=
CHECK=
case ${TTRO_variantCase} in
	warn0)
		printInfo "### Test warn level 0"
		OPTIONS+=' WARN_LEVEL=0';;
	warn1)
		printInfo "### Test warn level 1"
		OPTIONS+=' WARN_LEVEL=1';;
	warn2)
		printInfo "### Test warn level 2"
		OPTIONS+=' WARN_LEVEL=2';;
	warn3)
		printInfo "### Test warn level 3"
		OPTIONS+=' WARN_LEVEL=3';;
	check)
		printInfo "### Test warn level 2 with special warn file and default goal"
		OPTIONS+=' WARN_LEVEL=2'
		CHECK='true';;
	info)
		printInfo "### Test warn level 2 with special warn file and info goal"
		OPTIONS+=' WARN_LEVEL=2'
		GOALS='info'
		CHECK='true'
		NOBUILD='true';;
	help)
		printInfo "### goal help"
		OPTIONS+=' WARN_LEVEL=3'
		GOALS='help'
		NOBUILD='true';;
esac

PREPS=(
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/include" .'
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/src" .'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild/Makefile" .'
	'[[ -n $CHECK ]] || [[ -z ${TTRO_warnFile} ]] || cp "${TTRO_warnFile}" "warnings.mk"'
	'[[ -z $CHECK ]] || echo "cxxwarn2 = -Wcast-align" > "warnings.mk"'
	'getWarnString'
)

STEPS=(
	'executeLogAndSuccess make $OPTIONS $GOALS'
	'[[ -n $NOBUILD ]] || echoAndExecute "${BINDIR}/${TTRO_variantCase}"'
	'checkOut'
)

# Prepare the effective warn option string in TTRO_cxxwarn0 .. TTRO_cxxwarn3
getWarnString() {
	local cxxwarn0=''
	local cxxwarn1=''
	local cxxwarn2=''
	local cxxwarn3=''
	scanFile 'Makefile'
	if [[ -f warnings.mk ]]; then
		scanFile warnings.mk
	fi
	setVar 'TTRO_cxxwarn0' "$cxxwarn0"
	setVar 'TTRO_cxxwarn1' "$cxxwarn1"
	setVar 'TTRO_cxxwarn2' "$cxxwarn2"
	setVar 'TTRO_cxxwarn3' "$cxxwarn3"
	printInfo "Effective warn options are:"
	printInfo "cxxwarn0=$cxxwarn0"
	printInfo "cxxwarn1=$cxxwarn1"
	printInfo "cxxwarn2=$cxxwarn2"
	printInfo "cxxwarn3=$cxxwarn3"
}

# Scan file $1 and put the variable definition cxxwarn[0..3] in variables cxxwarn[0..3]
scanFile() {
	printInfo "$FUNCNAME $1"
	while read; do
		local i
		local x=''
		for i in 0 1 2 3; do
			if [[ $REPLY =~ cxxwarn${i}[[:blank:]]*\??=[[:blank:]](.*) ]]; then
				x="${BASH_REMATCH[1]}"
				eval "cxxwarn${i}"=\"\$x\"
				eval echo "\"cxxwarn${i}=\$cxxwarn${i}\""
			fi
		done
	done < "$1"
}

checkOut() {
	case ${TTRO_variantCase} in
		check|default|info|help|warn2)
			local myWarningString="${TTRO_cxxwarn2}*${TTRO_cxxwarn1}*${TTRO_cxxwarn0}";;
		warn0)
			local myWarningString="${TTRO_cxxwarn0}";;
		warn1)
			local myWarningString="${TTRO_cxxwarn1}*${TTRO_cxxwarn0}";;
		warn3)
			local myWarningString="${TTRO_cxxwarn3}*${TTRO_cxxwarn2}*${TTRO_cxxwarn1}*${TTRO_cxxwarn0}";;
		*)
			printErrorAndExit "Invalid case variant ${TTRO_variantCase}";;
	esac
	case ${TTRO_variantCase} in
		info)
			checkNoBuildOutput;;
		help)
			printInfo 'Nothing to check';;
		check)
			checkBuildOutput;;
		*)
			checkBuildOutput;;
	esac
}

checkBuildOutput() {
	echoAndExecute linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		"*${myWarningString}*\"src/m1.cpp\"" \
		"*${myWarningString}*\"src/m2.cc\""
}

checkNoBuildOutput() {
	echoAndExecute linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		"Building with WARN_LEVEL=2*${myWarningString}"
}