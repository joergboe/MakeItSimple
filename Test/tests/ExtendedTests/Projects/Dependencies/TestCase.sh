#--variantList='default defines m2h m1 m2 intdef mfile mfile2 config config2 default_nodb defines_nodb m1_nodb m2_nodb mfile_nodb config_nodb new cleantest'

if [[ ( ${TTRO_variantSuite} == "OneToOne" ) && ( ${TTRO_variantCase} == 'm2h' ) ]]; then
	setSkip "This variant makes no sense for project OneToOne."
fi
printInfo "Check expectations when the project was re-build."

BINDIR='debug/'
BUILDDIR='debug/build/src/'
SOURCEDIR='src/'
INCDIR='include/'
DEFINESDIR='include/defines/'
GOALS='all'
OPTIONS="-I ${TTRO_installDir}/include"
OPTIONS2=''
MODULE1='m1.cpp'
MODULE2='m2.cc'
MODULE3=''
MODULE4='m4.cpp'
BA1='m1.o'
BA2='m2.o'
BA3=''
BA4="${TTRO_variantCase}"
COPMP_DB='compile_commands.json'
CONF_DB='mks_last_config_store'
NO_CONF_DB_GENERATED=''
CLEAN=''

if [[ ( ${TTRO_variantSuite} == "OneToOne" ) || ( ${TTRO_variantSuite} == "ProjectInPlaceBuild" ) ]]; then
	BINDIR=''
	BUILDDIR=''
	SOURCEDIR=''
	INCDIR=''
	DEFINESDIR=''
fi
if [[ ${TTRO_variantSuite} == "OneToOne" ]]; then
	BA1='m1'
	BA2='m2'
	BA4=''
elif [[ ${TTRO_variantSuite} == "ProjectOutPlaceBuild2" ]]; then
	MODULE2='m2.c'
	MODULE3='hello_as_64.s'
	BA3='hello_as_64.o'
elif [[ ${TTRO_variantSuite} == "ProjectOutPlaceBuildC" ]]; then
	MODULE1='m1.c'
	MODULE2='m2.c'
	MODULE4='m4.c'
fi

case ${TTRO_variantCase} in
	default)
		printInfo "Build all twice with no change -> no second build expected.";;&
	config2*|mfile2*)
		printInfo "Build objects twice."
		GOALS="${BUILDDIR}${BA1} ${BUILDDIR}${BA2}";;&
	config*)
		printInfo "Build twice with configuration-change."
		OPTIONS2='WARN_LEVEL=1';;&
	mfile*)
		printInfo "Build twice with makefile-change.";;&
	*_nodb)
		printInfo "No configuration database generated."
		OPTIONS+=' DISABLE_CONFIG_CHECK=true'
		NO_CONF_DB_GENERATED='true';;
	new)
		printInfo "Introduce new module.";;
	cleantest)
		printInfo 'Build all, then clean, then build all'
		CLEAN='true';;
esac

PREPS=(
	'cp -r "${TTRO_inputDirSuite}/../../${TTRO_variantSuite}TestProject/"* .'
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y \"${TTRO_projectType}\" --noprompt"
	'echoAndExecute make ${OPTIONS} all'
	"cp -p ${BUILDDIR}${BA1} buildartefact1"
	"cp -p ${BUILDDIR}${BA2} buildartefact2"
	'[ -z ${BA3} ] || cp -p "${BUILDDIR}${BA3}" buildartefact3'
	'[ -z ${BA4} ] || cp -p "${BINDIR}${BA4}" buildartefact4'
	"cp -p ${COPMP_DB} buildartifact_comp_db"
	"[ -n \"${NO_CONF_DB_GENERATED}\" ] || cp -p ${CONF_DB} buildartifact_conf_db"
	'sleep 2'
)
if [[ -z ${CLEAN} ]]; then
	PREPS+=('changeFile')
else
	PREPS+=('echoAndExecute make ${OPTIONS} clean')
fi

# The main test run
STEPS=(
	'executeLogAndSuccess make ${OPTIONS} ${OPTIONS2} ${GOALS}'
	'ls --full-time buildartefact1 ${BUILDDIR}${BA1}'
	'ls --full-time buildartefact2 ${BUILDDIR}${BA2}'
	'[ -z ${BA3} ] || ls --full-time buildartefact3 "${BUILDDIR}${BA3}"'
	'[ -z ${BA4} ] || ls --full-time buildartefact4 "${BINDIR}${BA4}"'
	"ls --full-time buildartifact_comp_db ${COPMP_DB}"
	"[ -n \"${NO_CONF_DB_GENERATED}\" ] || ls --full-time buildartifact_conf_db ${CONF_DB}"
	'checkOutput'
)
if [[ ${TTRO_variantSuite} == "OneToOne" ]]; then
	STEPS+=(
		'./m1'
		'./m2'
	)
	if [[ ${TTRO_variantCase} == 'new' ]]; then
		STEPS+=('./m4')
	fi
else
	STEPS+=("./${BINDIR}${TTRO_variantCase}")
fi
if [ -n "${NO_CONF_DB_GENERATED}" ]; then
	STEPS+=('! [ -f "${CONF_DB}" ]')
else
	STEPS+=('[ -f "${CONF_DB}" ]')
fi
changeFile() {
	case ${TTRO_variantCase} in
		default*) printInfo "No changes to make";;
		config*) printInfo "No changes to make";;
		defines*) changeAFile "${DEFINESDIR}definitions.h" 'maxcount = 3' 'maxcount = 2';;
		m2h*) changeAFile "${INCDIR}m2.h" 'void hellom2();' 'void hellom2(); /*added comment*/';;
		m1*) changeAFile "${SOURCEDIR}${MODULE1}" 'Hello World Program m1' 'Hello World Program variant m1cpp';;
		m2*) changeAFile "${SOURCEDIR}${MODULE2}" 'Hello World Program m2' 'Hello World Program variant m2cc';;
		intdef) changeAFile "${SOURCEDIR}internal_definitions.h" 'A_CONST = 11' 'A_CONST = 55';;
		mfile*) printInfo "Touch Makefile"; touch Makefile;;
		new)
			if [[ ${TTRO_variantSuite} != "OneToOne" ]]; then
				changeAFile "${SOURCEDIR}${MODULE1}" 'return 0;' 'void foo(); foo(); return 0;'
				if [[ $MODULE4 == *.c ]]; then
					echo -e '#include <stdio.h>\nvoid foo(void) {\n  printf("Hello World foo\\n");  return;\n}\n' >> "${SOURCEDIR}${MODULE4}"
				else
					echo -e '#include <iostream>\nvoid foo() {\n  std::cout << "Hello World foo" << std::endl;\n  return;\n}\n' >> "${SOURCEDIR}${MODULE4}"
				fi
			else
				echo -e '#include <iostream>\nint main() {\n  std::cout << "Hello World foo" << std::endl;\n  return 0;\n}\n' >> "${SOURCEDIR}${MODULE4}"
			fi;;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;

	esac
}

checkOutput() {
	printInfo "Check regular build artifacts"
	case ${TTRO_variantCase} in
		# nothing build
		default*|config_nodb)
			buildNotExpected "${BUILDDIR}${BA1}" "buildartefact1"
			buildNotExpected "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildNotExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildNotExpected "${BINDIR}${BA4}" "buildartefact4";;
		# all changed
		mfile|mfile_nodb|config|cleantest)
			buildExpected "${BUILDDIR}${BA1}" "buildartefact1"
			buildExpected "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildExpected "${BINDIR}${BA4}" "buildartefact4";;
		m2h)
			buildExpected "${BUILDDIR}${BA1}" "buildartefact1"
			buildExpected "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildNotExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildExpected "${BINDIR}${BA4}" "buildartefact4";;
		# objects changed
		mfile2|config2)
			buildExpected "${BUILDDIR}${BA1}" "buildartefact1"
			buildExpected "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildNotExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildNotExpected "${BINDIR}${BA4}" "buildartefact4";;
		# m1 and target changed
		m1*)
			buildExpected    "${BUILDDIR}${BA1}" "buildartefact1"
			buildNotExpected "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildNotExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildExpected "${BINDIR}${BA4}" "buildartefact4";;
		# m2 and target changed
		m2*|defines*|intdef)
			buildNotExpected "${BUILDDIR}${BA1}" "buildartefact1"
			buildExpected    "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildNotExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildExpected "${BINDIR}${BA4}" "buildartefact4";;
		new)
			if [[ ${TTRO_variantSuite} == "OneToOne" ]]; then
				buildNotExpected "${BUILDDIR}${BA1}" "buildartefact1"
			else
				buildExpected "${BUILDDIR}${BA1}" "buildartefact1"
			fi
			buildNotExpected    "${BUILDDIR}${BA2}" "buildartefact2"
			[ -z ${BA3} ] || buildNotExpected "${BUILDDIR}${BA3}" "buildartefact3"
			[ -z ${BA4} ] || buildExpected "${BINDIR}${BA4}" "buildartefact4";;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
	printInfo "Check compilation database"
	case ${TTRO_variantCase} in
		# nothing build
		default*|config_nodb)
			buildNotExpected "${COPMP_DB}" "buildartifact_comp_db";;
		# all changed
		mfile|mfile_nodb|new)
			buildExpected "${COPMP_DB}" "buildartifact_comp_db";;
		config)
			buildExpected "${COPMP_DB}" "buildartifact_comp_db";;
		# objects changed
		mfile2|config2)
			# comp db is not changed because compdb goal is not invoked
			buildNotExpected "${COPMP_DB}" "buildartifact_comp_db";;
		# m1 and target changed
		m1*|m2*|defines*|intdef)
			buildNotExpected "${COPMP_DB}" "buildartifact_comp_db";;
		cleantest)
			buildNotExpected "${COPMP_DB}" "buildartifact_comp_db";;
		*)
			printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
	esac
	printInfo "Check configuration database"
	case ${TTRO_variantCase} in
		*_nodb)
			! [[ -f ${CONF_DB} ]] || setFailure "Configuration database file ${CONF_DB} exists";;
		# nothing build
		default|new)
			buildNotExpected "${CONF_DB}" "buildartifact_conf_db";;
		# all changed
		mfile*)
			# configuration not changed in case of makefile !
			buildNotExpected "${CONF_DB}" "buildartifact_conf_db";;
		config*)
			buildExpected "${CONF_DB}" "buildartifact_conf_db";;
		m1*|m2*|defines|intdef)
			buildNotExpected "${CONF_DB}" "buildartifact_conf_db";;
		cleantest)
			buildNotExpected "${CONF_DB}" "buildartifact_conf_db";;
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