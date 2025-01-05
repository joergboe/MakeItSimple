echo "Check version of mktsimple wizzard and all make scripts"

testStep() {
	temp=$("${TTRO_installDir}/bin/mktsimple" --version)
	WIZ_VERS="${temp##*\ }"
	echo "Wizard version: ${WIZ_VERS}"
	for make_name in in_place_cpp.mk  one_to_one_cpp.mk  out_place_c.mk  out_place_cpp.mk  out_place.mk; do
		temp=$(make -f "${TTRO_installDir}/share/mktsimple/${make_name}" show | grep "Make It Simple version")
		vers="${temp##*\ }"
		echo "${make_name} version: ${vers}"
		if [[ "${vers}" != "${WIZ_VERS}" ]]; then
			setFailure "${make_name} version does not match Wizzard version"
		fi
	done
}
