#--variantList='default_goal all_goal compdb_goal build_goal clean_goal purge_goal show_goal help_goal cleanall__goal'

printInfo "Test makefile if hidden directory can not be created."

GOALS=
EXPECT_SUCCESS=

case ${TTRO_variantCase} in
	default_goal)
		: ;;
	all_goal)
		GOALS='all';;
	compdb_goal)
		GOALS='compdb';;
	build_goal)
		GOALS='build';;
	clean_goal)
		GOALS='clean'
		EXPECT_SUCCESS='true';;
	purge_goal)
		GOALS='purge'
		EXPECT_SUCCESS='true';;
	show_goal)
		GOALS='show'
		EXPECT_SUCCESS='true';;
	help_goal)
		GOALS='help'
		EXPECT_SUCCESS='true';;
	cleanall__goal)
		GOALS='clean all';;
	*)
		printErrorAndExit "Program Error variant ${TTRO_variantCase}";;
esac

PREPS=(
	"cp -r \"${TTRO_inputDirSuite}/../../${TTRO_variantSuite}TestProject/\"* ."
	"\"${TTRO_installDir}/bin/mktsimple\" -p . -y \"${TTRO_projectType}\" --noprompt"
	"touch .mktsimple"
)

if [[ -n ${EXPECT_SUCCESS} ]]; then
	STEPS=("executeLogAndSuccess make ${GOALS}")
else
	STEPS=("executeLogAndError make ${GOALS}")
fi
