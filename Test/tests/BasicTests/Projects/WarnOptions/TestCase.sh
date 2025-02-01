#--variantList='check default warn0 warn1 warn2 warn3 warn4 warn5 infoGoal helpGoal auto'

OPTIONS=''
BINDIR=''
GOALS=
NOBUILD=
LOCAL_WARN_FILE=
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
	warn4)
		printInfo "### Test warn level 4"
		OPTIONS+=' WARN_LEVEL=4';;
	warn5)
		printInfo "### Test warn level 5"
		OPTIONS+=' WARN_LEVEL=5';;
	check)
		printInfo "### Test warn level 2 with special warn file and default goal"
		OPTIONS+=' WARN_LEVEL=2 MAKEFILE_WARN=warnings.mk'
		LOCAL_WARN_FILE='true'
		unset MAKEFILE_WARN
		unset MAKEFILE_WARN_C;;
	infoGoal)
		printInfo "### Test warn level 2 with special warn file and show goal"
		OPTIONS+=' WARN_LEVEL=2 MAKEFILE_WARN=warnings.mk'
		GOALS='show'
		LOCAL_WARN_FILE='true'
		NOBUILD='true'
		unset MAKEFILE_WARN
		unset MAKEFILE_WARN_C;;
	helpGoal)
		printInfo "### goal help"
		OPTIONS+=' WARN_LEVEL=3'
		GOALS='help'
		NOBUILD='true';;
	auto)
		printInfo "### Test warn level 5 with automatic warn file detection"
		OPTIONS+=" WARN_LEVEL=5 -I ${TTRO_installDir}/include"
		mywarn_file="${TTRO_warnFile}"
		mywarn_file_c="${TTRO_warnFileC}"
		unset MAKEFILE_WARN
		unset MAKEFILE_WARN_C
esac

if [[ ${TTRO_variantSuite} == 'ProjectOutPlaceBuildC' ]]; then
	if isExistingAndTrue 'MAKEFILE_WARN_C'; then
		MAKEFILE_WARN="${MAKEFILE_WARN_C}"
		export MAKEFILE_WARN_C
	fi
fi

INCDIROPT=
if [[ "${TTRO_variantSuite}" = ProjectOutPlaceBuild* ]]; then
	INCDIROPT+=' --include-dir include'
fi

PREPS=(
	'cp -r ${TTRO_inputDirSuite}/../../${TTRO_variantSuite}TestProject/* .'
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y ${TTRO_projectType} ${INCDIROPT} --noprompt"
	'[[ -z $LOCAL_WARN_FILE ]] || echo -e "cxxwarn2 = -Wcast-align\ncwarn2 = -Wcast-align" > "warnings.mk"'
	'getWarnString'
)

MODULE1='m1.cpp'
MODULE2='m2.cc'
M1_IS_C=''
M2_IS_C=''
STEPS=(	'executeLogAndSuccess make $OPTIONS $GOALS' )
if [[ "${TTRO_variantSuite}" = 'OneToOne' ]]; then
	STEPS+=(
		'[[ -n $NOBUILD ]] || echoAndExecute ./m1'
		'[[ -n $NOBUILD ]] || echoAndExecute ./m2'
	)
elif [[ "${TTRO_variantSuite}" = 'ProjectInPlaceBuild' ]]; then
	STEPS+=( '[[ -n $NOBUILD ]] || echoAndExecute "./${TTRO_variantCase}"' )
else
	STEPS+=( '[[ -n $NOBUILD ]] || echoAndExecute "${BINDIR}/${TTRO_variantCase}"' )
	BINDIR='debug'
fi
if [[ ( "${TTRO_variantSuite}" = 'ProjectOutPlaceBuildC' ) || ( "${TTRO_variantSuite}" = 'ProjectOutPlaceBuild2') ]]; then
	MODULE2='m2.c'
	M2_IS_C='true'
fi
if [[ "${TTRO_variantSuite}" = 'ProjectOutPlaceBuildC' ]]; then
	MODULE1='m1.c'
	M1_IS_C='true'
fi
STEPS+=( 'checkOut' )


# Prepare the effective warn option string in TTRO_cxxwarn0 .. TTRO_cxxwarn3
getWarnString() {
	local cxxwarn0='' cwarn0=''
	local cxxwarn1='' cwarn1=''
	local cxxwarn2='' cwarn2=''
	local cxxwarn3='' cwarn3=''
	local cxxwarn4='' cwarn4=''
	local cxxwarn5='' cwarn5=''
	scanFile 'Makefile'
	if isExistingAndTrue 'MAKEFILE_WARN'; then
		scanFile "${MAKEFILE_WARN}"
	elif isExistingAndTrue 'mywarn_file'; then
		scanFile "${mywarn_file}"
	elif [[ -f warnings.mk ]]; then
		scanFile warnings.mk
	fi
	if isExistingAndTrue 'MAKEFILE_WARN_C'; then
		scanFile "${MAKEFILE_WARN_C}"
	elif isExistingAndTrue 'mywarn_file_c'; then
		scanFile "${mywarn_file_c}"
	fi
	local i x n
	for i in 0 1 2 3 4 5; do
		eval "n=\${cwarn${i}}"
		if [[ "${n}" == \$?cxxwarn${i}? ]]; then
			eval "cwarn${i}=\${cxxwarn${i}}"
		fi
	done
	setVar 'TTRO_cxxwarn0' "$cxxwarn0"
	setVar 'TTRO_cxxwarn1' "$cxxwarn1"
	setVar 'TTRO_cxxwarn2' "$cxxwarn2"
	setVar 'TTRO_cxxwarn3' "$cxxwarn3"
	setVar 'TTRO_cxxwarn4' "$cxxwarn4"
	setVar 'TTRO_cxxwarn5' "$cxxwarn5"
	setVar 'TTRO_cwarn0' "$cwarn0"
	setVar 'TTRO_cwarn1' "$cwarn1"
	setVar 'TTRO_cwarn2' "$cwarn2"
	setVar 'TTRO_cwarn3' "$cwarn3"
	setVar 'TTRO_cwarn4' "$cwarn4"
	setVar 'TTRO_cwarn5' "$cwarn5"
	printInfo "Effective warn options are:"
	printInfo "cxxwarn0=$cxxwarn0"
	printInfo "cxxwarn1=$cxxwarn1"
	printInfo "cxxwarn2=$cxxwarn2"
	printInfo "cxxwarn3=$cxxwarn3"
	printInfo "cxxwarn4=$cxxwarn4"
	printInfo "cxxwarn5=$cxxwarn5"
	printInfo "cwarn0=$cwarn0"
	printInfo "cwarn1=$cwarn1"
	printInfo "cwarn2=$cwarn2"
	printInfo "cwarn3=$cwarn3"
	printInfo "cwarn4=$cwarn4"
	printInfo "cwarn5=$cwarn5"
}

# Scan file $1 and put the variable definition cxxwarn[0..3] in variables cxxwarn[0..3]
scanFile() {
	printInfo "${FUNCNAME[0]} $1"
	local continuation=''
	local buffer=''
	# special handling of continuation lines due to posix compatibility of the make file
	# posix make inserts one space for a backslash new-line, but bash doesn't
	while read -r; do
		if [[ ${continuation} ]]; then
			local temp="${REPLY#${REPLY%%[![:space:]]*}}"
			buffer="${buffer} ${temp}"   # insert a single space in a continued line
		else
			buffer="${REPLY}"
		fi
		if [[ $REPLY == *\\ ]]; then
			buffer=${buffer:0: -1}
			continuation='true'
		else
			continuation=''
			local i
			local x=''
			for i in 0 1 2 3 4 5; do
				if [[ $buffer =~ cxxwarn${i}[[:blank:]]*\??=[[:blank:]](.*) ]]; then
					x="${BASH_REMATCH[1]}"
					eval "cxxwarn${i}"=\"\$x\"
					eval echo "\"cxxwarn${i}=\$cxxwarn${i}\""
				fi
			done
			for i in 0 1 2 3 4 5; do
				if [[ $buffer =~ cwarn${i}[[:blank:]]*\??=[[:blank:]](.*) ]]; then
					x="${BASH_REMATCH[1]}"
					eval "cwarn${i}"=\"\$x\"
					eval echo "\"cwarn${i}=\$cwarn${i}\""
				fi
			done
		fi
	done < "$1"
}

checkOut() {
	case ${TTRO_variantCase} in
		check|default|infoGoal|helpGoal|warn2)
			local  myWarningString="${TTRO_cxxwarn1}*${TTRO_cxxwarn2}"
			local myCWarningString="${TTRO_cwarn1}*${TTRO_cwarn2}";;
		warn0)
			local  myWarningString="${TTRO_cxxwarn0}"
			local myCWarningString="${TTRO_cwarn0}";;
		warn1)
			local  myWarningString="${TTRO_cxxwarn1}"
			local myCWarningString="${TTRO_cwarn1}";;
		warn3)
			local  myWarningString="${TTRO_cxxwarn1}*${TTRO_cxxwarn2}*${TTRO_cxxwarn3}"
			local myCWarningString="${TTRO_cwarn1}*${TTRO_cwarn2}*${TTRO_cwarn3}";;
		warn4)
			local  myWarningString="${TTRO_cxxwarn1}*${TTRO_cxxwarn2}*${TTRO_cxxwarn3}*${TTRO_cxxwarn4}"
			local myCWarningString="${TTRO_cwarn1}*${TTRO_cwarn2}*${TTRO_cwarn3}*${TTRO_cwarn4}";;
		warn5|auto)
			local  myWarningString="${TTRO_cxxwarn1}*${TTRO_cxxwarn2}*${TTRO_cxxwarn3}*${TTRO_cxxwarn4}*${TTRO_cxxwarn5}"
			local myCWarningString="${TTRO_cwarn1}*${TTRO_cwarn2}*${TTRO_cwarn3}*${TTRO_cwarn4}*${TTRO_cwarn5}";;
		*)
			printErrorAndExit "Invalid case variant ${TTRO_variantCase}";;
	esac
	case ${TTRO_variantCase} in
		infoGoal)
			checkNoBuildOutput;;
		helpGoal)
			printInfo 'Nothing to check';;
		check)
			checkBuildOutput;;
		*)
			checkBuildOutput;;
	esac
}

checkBuildOutput() {
	if [[ -z $M1_IS_C ]]; then
		local pattern1="*${MODULE1}*${myWarningString}*"
	else
		local pattern1="*${MODULE1}*${myCWarningString}*"
	fi
	if [[ -z $M2_IS_C ]]; then
		local pattern2="*${MODULE2}*${myWarningString}*"
	else
		local pattern2="*${MODULE2}*${myCWarningString}*"
	fi

	echoAndExecute linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		"${pattern1}" \
		"${pattern2}"
}

checkNoBuildOutput() {
	echoAndExecute linewisePatternMatchInterceptAndSuccess "${TT_evaluationFile}" 'true' \
		"Building with WARN_LEVEL=2*${myWarningString}"
}