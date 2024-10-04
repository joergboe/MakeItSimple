#--variantList='default defines m2h m1cpp m2cc intdef mfile mfile2 config config2 default_nodb defines_nodb m1cpp_nodb m2cc_nodb mfile_nodb config_nodb'

BINDIR='debug'

GOALS='all'
OPTIONS=''
OPTIONS2=''
case ${TTRO_variantCase} in
	config2|mfile2)
		GOALS="${BINDIR}/build/src/m1.o ${BINDIR}/build/src/m2.o";;&
	config*)
		OPTIONS2='WARN_LEVEL=1';;&
	*_nodb)
		OPTIONS='DISABLE_COMPILE_DB=true';;
esac

PREPS=(
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/include" .'
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/src" .'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild/Makefile" .'
	'echoAndExecute make ${OPTIONS} all'
	"cp -p ${BINDIR}/build/src/m1.o buildartefact1"
	"cp -p ${BINDIR}/build/src/m2.o buildartefact2"
	"cp -p ${BINDIR}/${TTRO_variantCase} buildartefact3"
	'sleep 2'
	'changeFile'
)

# The main test run
STEPS=(
	'executeLogAndSuccess make ${OPTIONS} ${OPTIONS2} ${GOALS}'
	'ls --full-time buildartefact1 ${BINDIR}/build/src/m1.o'
	'ls --full-time buildartefact2 ${BINDIR}/build/src/m2.o'
	'ls --full-time buildartefact3 ${BINDIR}/${TTRO_variantCase}'
	'checkOutput'
	"${BINDIR}/${TTRO_variantCase}"
)

changeFile() {
	case ${TTRO_variantCase} in
		default*) printInfo "No changes to make";;
		config*) printInfo "No changes to make";;
		defines*) changeAFile 'include/defines/definitions.h' 'maxcount = 3' 'maxcount = 2';;
		m2h*) changeAFile 'include/m2.h' 'void hellom2();' 'void hellom2(void);';;
		m1cpp*) changeAFile 'src/m1.cpp' 'Hello World Program m1' 'Hello World Program variant m1cpp';;
		m2cc*) changeAFile 'src/m2.cc' 'Hello World Program m2' 'Hello World Program variant m2cc';;
		intdef) changeAFile 'src/internal_definitions.hpp' 'A_CONST = 11' 'A_CONST = 55';;
		mfile*) printInfo "Touch Makefile"; touch Makefile;;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;

	esac
}

checkOutput() {
	case ${TTRO_variantCase} in
		# nothing build
		default*)
			buildNotExpected "${BINDIR}/build/src/m1.o" "buildartefact1"
			buildNotExpected "${BINDIR}/build/src/m2.o" "buildartefact2"
			buildNotExpected "${BINDIR}/${TTRO_variantCase}" "buildartefact3";;
		# all changed
		mfile|mfile_nodb|config|m2h|config_nodb)
			buildExpected "${BINDIR}/build/src/m1.o" "buildartefact1"
			buildExpected "${BINDIR}/build/src/m2.o" "buildartefact2"
			buildExpected "${BINDIR}/${TTRO_variantCase}" "buildartefact3";;
		# objects changed
		mfile2|config2)
			buildExpected "${BINDIR}/build/src/m1.o" "buildartefact1"
			buildExpected "${BINDIR}/build/src/m2.o" "buildartefact2"
			buildNotExpected "${BINDIR}/${TTRO_variantCase}" "buildartefact3";;
		# m1 and target changed
		m1cpp*)
			buildExpected    "${BINDIR}/build/src/m1.o" "buildartefact1"
			buildNotExpected "${BINDIR}/build/src/m2.o" "buildartefact2"
			buildExpected "${BINDIR}/${TTRO_variantCase}" "buildartefact3";;
		# m2 and target changed
		m2cc*|defines*|intdef)
			buildNotExpected "${BINDIR}/build/src/m1.o" "buildartefact1"
			buildExpected    "${BINDIR}/build/src/m2.o" "buildartefact2"
			buildExpected "${BINDIR}/${TTRO_variantCase}" "buildartefact3";;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
}

buildExpected() {
	[[ -e "$1" ]]
	[[ -e "$2" ]]
	if [[ "$1" -nt "$2" ]]; then
		printInfo "$1 was build!"
	else
		setFailure "$1 was NOT build!"
	fi
	return 0
}

buildNotExpected() {
	[[ -e "$1" ]]
	[[ -e "$2" ]]
	if [[ "$1" -nt "$2" ]]; then
		setFailure "$1 WAS build!"
	else
		printInfo "$1 was not build!"
	fi
	return 0
}

changeAFile() {
	local filename="$1"
	local searchPattern="$2"
	local replace="$3"
	echo "filename=$1"
	echo "searchPattern=$2"
	echo "replace=$3"
	mv "${filename}" "temp.xx"
	while read -r; do
		echo "${REPLY/$2/$3}" >> "${filename}"
	done < "temp.xx"
}