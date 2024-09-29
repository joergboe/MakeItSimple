#--variantList='default defines m1cpp m2cc makefile makefile2 config config2 default_nodb defines_nodb m1cpp_nodb m2cc_nodb makefile_nodb config_nodb'
GOALS='all'
OPTIONS=''
OPTIONS2=''
case ${TTRO_variantCase} in
	config2|makefile2)
		GOALS='m1 m2';;&
	config*)
		OPTIONS2='BUILD_MODE=run';;&
	*_nodb)
		OPTIONS='DISABLE_COMPILE_DB=true';;
esac

PREPS=(
	'cp ${TTRO_inputDirSuite}/../OneToOneTestProject/* .'
	'cp "${TTRO_installDir}/OneToOne/Makefile" .'
	'make ${OPTIONS} ${GOALS}'
	"cp -p m1 buildartefact1"
	"cp -p m2 buildartefact2"
	'sleep 2'
	'changeFile'
)

# The main test run
STEPS=(
	'executeLogAndSuccess make ${OPTIONS} ${OPTIONS2} ${GOALS}'
	'ls --full-time buildartefact1 m1'
	'ls --full-time buildartefact2 m2'
	'checkOutput'
	"./m1"
	"./m2"
)

changeFile() {
	case ${TTRO_variantCase} in
		default*|config*) printInfo "No changes to make";;
		defines*) changeAFile 'definitions.h' 'maxcount = 3' 'maxcount = 2';;
		m1cpp*) changeAFile 'm1.cpp' 'Hello World Program m1' 'Hello World Program variant m1cpp';;
		m2cc*) changeAFile 'm2.cc' 'Hello World Program m2' 'Hello World Program variant m2cc';;
		makefile*) printInfo "Touch Makefile"; touch Makefile;;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
}

checkOutput() {
	case ${TTRO_variantCase} in
		# nothing build
		default*|config_nodb)
			if [[ "m1" -nt "buildartefact1" ]]; then
				setFailure "m1 was build!"
			else
				printInfo "m1 was NOT build!"
			fi
			if [[ "m2" -nt "buildartefact2" ]]; then
				setFailure "m2 was build!"
			else
				printInfo "m2 was NOT build!"
			fi;;
		# m2 was build
		defines*|m2cc*)
			if [[ "m1" -nt "buildartefact1" ]]; then
				setFailure "m1 was build!"
			else
				printInfo "m1 was NOT build!"
			fi
			if [[ "m2" -nt "buildartefact2" ]]; then
				printInfo "m2 was build!"
			else
				setFailure "m2 was NOT build!"
			fi;;
		# m1 build
		m1cpp*)
			if [[ "m1" -nt "buildartefact1" ]]; then
				printInfo "m1 was build!"
			else
				setFailure "m1 was NOT build!"
			fi
			if [[ "m2" -nt "buildartefact2" ]]; then
				setFailure "m2 was build!"
			else
				printInfo "m2 was NOT build!"
			fi;;
		# all build
		makefile*|config|config2)
			if [[ "m1" -nt "buildartefact1" ]]; then
				printInfo "m1 was build!"
			else
				setFailure "m1 was NOT build!"
			fi
			if [[ "m2" -nt "buildartefact2" ]]; then
				printInfo "m2 was build!"
			else
				setFailure "m2 was NOT build!"
			fi;;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
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
