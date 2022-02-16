#--variantList='default defines m2h m1cpp m2cc intdef'

BINDIR='debug'

PREPS=(
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/include" .'
	'cp -r "${TTRO_inputDirSuite}/../ProjectOutPlaceBuildTestProject/src" .'
	'cp "${TTRO_installDir}/ProjectOutPlaceBuild/Makefile" .'
	'make'
	"cp -p ${BINDIR}/${TTRO_variantCase} ${BINDIR}/buildartefact1"
	'changeFile'
	'sleep 1'
)

# The main test run
STEPS=(
	'executeLogAndSuccess make VERBOSE=1'
	'ls --full-time ${BINDIR}'
	'checkOutput'
	"${BINDIR}/${TTRO_variantCase}"
)

changeFile() {
	case ${TTRO_variantCase} in
		default) printInfo "No changes to make";;
		defines) changeAFile 'include/defines/definitions.h' 'maxcount = 3' 'maxcount = 2';;
		m2h) changeAFile 'include/m2.h' 'void hellom2();' 'void hellom2(void);';;
		m1cpp) changeAFile 'src/m1.cpp' 'Hello World Program m1' 'Hello World Program variant m1cpp';;
		m2cc) changeAFile 'src/m2.cc' 'Hello World Program m2' 'Hello World Program variant m2cc';;
		intdef) changeAFile 'src/internal_definitions.hpp' 'A_CONST = 11' 'A_CONST = 55';;
	esac
}

checkOutput() {
	case ${TTRO_variantCase} in
		default)
			if [[ "${BINDIR}/${TTRO_variantCase}" -nt "${BINDIR}/buildartefact1" ]]; then
				setFailure "${BINDIR}/${TTRO_variantCase} was build!"
			else
				printInfo "${BINDIR}/${TTRO_variantCase} was NOT build!"
			fi;;
		*)
			if ! [[ "${BINDIR}/${TTRO_variantCase}" -nt "${BINDIR}/buildartefact1" ]]; then
				setFailure "${BINDIR}/${TTRO_variantCase} was not build!"
			else
				printInfo "${BINDIR}/${TTRO_variantCase} WAS build!"
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