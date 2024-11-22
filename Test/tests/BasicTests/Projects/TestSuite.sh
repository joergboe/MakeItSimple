#--variantList="OneToOne ProjectInPlaceBuild ProjectOutPlaceBuild ProjectOutPlaceBuildC ProjectOutPlaceBuild2"

declare -p TTRO_installDir

case "${TTRO_variantSuite}" in
	OneToOne) TTRO_projectType='otocpp';;
	ProjectInPlaceBuild) TTRO_projectType='ipbcpp';;
	ProjectOutPlaceBuild) TTRO_projectType='opbcpp';;
	ProjectOutPlaceBuildC) TTRO_projectType='opbc';;
	ProjectOutPlaceBuild2) TTRO_projectType='opb';;
	*)
		printErrorAndExit "invalid suite variant: ${TTRO_variantSuite}"
esac
