#--variantList='default defines m2h m1cpp m2cc mfile mfile2 config config2 default_nodb defines_nodb m1cpp_nodb m2cc_nodb mfile_nodb config_nodb'
GOALS='all'
OPTIONS=''
OPTIONS2=''
case ${TTRO_variantCase} in
	config2|mfile2)
		GOALS='m1.o m2.o';;&
	config*)
		OPTIONS2='BUILD_MODE=run';;&
	*_nodb)
		OPTIONS='DISABLE_COMPILE_DB=true';;
esac

PREPS=(
	'cp ${TTRO_inputDirSuite}/../ProjectInPlaceBuildTestProject/* .'
	'cp "${TTRO_installDir}/ProjectInPlaceBuild/Makefile" .'
	'echoAndExecute make ${OPTIONS} all'
	"cp -p m1.o buildartefact1"
	"cp -p m2.o buildartefact2"
	"cp -p ${TTRO_variantCase} buildartefact3"
	'sleep 2'
	'changeFile'
)

# The main test run
STEPS=(
	'executeLogAndSuccess make ${OPTIONS} ${OPTIONS2} ${GOALS}'
	'ls --full-time buildartefact1 m1.o'
	'ls --full-time buildartefact2 m2.o'
	'ls --full-time buildartefact3 ${TTRO_variantCase}'
	'checkOutput'
	"./${TTRO_variantCase}"
)

changeFile() {
	case ${TTRO_variantCase} in
		default*|config*) printInfo "No changes to make";;
		defines*) changeAFile 'definitions.h' 'maxcount = 3' 'maxcount = 2';;
		m1cpp*) changeAFile 'm1.cpp' 'Hello World Program m1' 'Hello World Program variant m1cpp';;
		m2h*) changeAFile 'm2.h' 'void hellom2();' 'void hellom2(void);';;
		m2cc*) changeAFile 'm2.cc' 'Hello World Program m2' 'Hello World Program variant m2cc';;
		mfile*) printInfo "Touch Makefile"; touch Makefile;;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
}

checkOutput() {
	case ${TTRO_variantCase} in
		# nothing build
		default*|config_nodb)
			buildNotExpected "m1.o" "buildartefact1"
			buildNotExpected "m2.o" "buildartefact2"
			buildNotExpected "${TTRO_variantCase}" "buildartefact3";;
		# all changed
		mfile|mfile_nodb|config|m2h)
			buildExpected "m1.o" "buildartefact1"
			buildExpected "m2.o" "buildartefact2"
			buildExpected "${TTRO_variantCase}" "buildartefact3";;
		# objects changed
		mfile2|config2)
			buildExpected "m1.o" "buildartefact1"
			buildExpected "m2.o" "buildartefact2"
			buildNotExpected "${TTRO_variantCase}" "buildartefact3";;
		# m1 and target changed
		m1cpp*)
			buildExpected    "m1.o" "buildartefact1"
			buildNotExpected "m2.o" "buildartefact2"
			buildExpected "${TTRO_variantCase}" "buildartefact3";;
		# m2 and target changed
		m2cc*|defines*)
			buildNotExpected "m1.o" "buildartefact1"
			buildExpected    "m2.o" "buildartefact2"
			buildExpected "${TTRO_variantCase}" "buildartefact3";;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
}

buildExpected() {
	if [[ "$1" -nt "$2" ]]; then
		printInfo "$1 was build!"
	else
		setFailure "$1 was NOT build!"
	fi
	return 0
}

buildNotExpected() {
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