#--variantList='default defines m2h m1cpp m2cc'

PREPS=(
	'cp ${TTRO_inputDirSuite}/../ProjectInPlaceBuildTestProject/* .'
	'cp "${TTRO_installDir}/ProjectInPlaceBuild/Makefile" .'
	'make'
	"cp -p ${TTRO_variantCase} buildartefact1"
	'changeFile'
	'sleep 1'
)

# The main test run
STEPS=(
	'executeLogAndSuccess make'
	'ls --full-time buildartefact1 ${TTRO_variantCase}'
	'checkOutput'
	"./${TTRO_variantCase}"
)

changeFile() {
	case ${TTRO_variantCase} in
		default) printInfo "No changes to make";;
		defines) changeAFile 'definitions.h' 'maxcount = 3' 'maxcount = 2';;
		m2h) changeAFile 'm2.h' 'void hellom2();' 'void hellom2(void);';;
		m1cpp) changeAFile 'm1.cpp' 'Hello World Program m1' 'Hello World Program variant m1cpp';;
		m2cc) changeAFile 'm2.cc' 'Hello World Program m2' 'Hello World Program variant m2cc';;
	esac
}

checkOutput() {
	case ${TTRO_variantCase} in
		default)
			if [[ "${TTRO_variantCase}" -nt "buildartefact1" ]]; then
				setFailure "${TTRO_variantCase} was build!"
			else
				printInfo "${TTRO_variantCase} was NOT build!"
			fi;;
		*)
			if ! [[ "${TTRO_variantCase}" -nt "buildartefact1" ]]; then
				setFailure "${TTRO_variantCase} was not build!"
			else
				printInfo "${TTRO_variantCase} WAS build!"
			fi;;
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