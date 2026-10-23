# Makefile translates System Header Units and User Header Units compact version
#
# This script requires two variables with the list Header Unit list to translate
# CXX_SYSTEM_HEADER_UNITS and CXX_USER_HEADER_UNITS.
#
# Stage 0 checks for changes in the configuration and triggers a complete recompilation if necessary.
#
# Stage 1 determines the dependency tree for each Header Unit. A Dependency File ('%.dep') contains
# the legacy header dependency tree for a Header Unit. Target of the dependency tree is the
# Dependency File itself.
#
# Stage 2a determines the original header file for each header unit based on the dependency tree (the first rule).
# Furthermore, the logical source name and the CIM filename are identified.
#
# Stage 2b generates a mapping database and the header map file (header-map.modm) using the data obtained in
# this way. The mappung database is exported to make in form of a variable ('header-unit.dep'):
#        CXX_KIND_UNIT_SRC_MOD_CMI_LIST += <kind>;<unit name>;<source name>;<logical module>;<cmi name>
#
# Stage 2c scans the (header) dependencies of a header unit (the first rule). If a dependency exists in the
# mapping database, a rule with the dependend cmi file is added to file 'header-unit.dep'.
#        <my-cmi> : <dpendency-cmi1> <dpendency-cmi2>
#
# Stage 3 translates header unit source files to cmi files. The Dependency File ('%.dep') substitutes all header
# dependencies of the cmi file.
#
# Stage 4 makes the final header part of the module map 'module-map-h.txt' to be used by the main script.
#
# Relative header file locations are considered relative to the current directory.
#
# Intermediate build artifacts are stored in directories 'build/system' and 'build/user'.
# The files 'header-units-list', 'header-units-config', 'header-map.modm' and 'module-map-h.txt' are stored in
# directory 'build'.

# getting path of this makefile
this_makefile ::= $(lastword $(MAKEFILE_LIST))
bin ::= $(dir $(this_makefile))

# checking command-line option -s
single_make_options ::= $(firstword -$(MAKEFLAGS))
silent =
ifeq (s,$(findstring s,$(single_make_options)))
  silent = 1
endif

# intro
$(if $(silent),,$(info )$(info **** $(if $(MAKE_RESTARTS),RESTART # $(MAKE_RESTARTS),START) $(this_makefile) in $(CURDIR).))

# include functions and variables
include $(bin)common-definitions.mk
# do not try update common-definitions.mk
.PHONY : $(bin)common-definitions.mk
$(if $(common-definitions),,$(error $(red)ERROR: $(bin)common-definitions.mk not included$(res)))

# removing all the built-in pattern rules
MAKEFLAGS += -r

# default target
.PHONY : all
all : all_

.DELETE_ON_ERROR:

# do not try update this makefile
$(bin)Makefile-header-units-compact.mk : ;

# checking goals
cleanup_goals = clean purge
goals ::= $(MAKECMDGOALS)
# The variable cleanup is also used to prevent inclusion of dependent makefiles.
cleanup ::= $(filter $(cleanup_goals),$(goals))
ifneq ($(cleanup),)
  ifneq (,$(filter-out $(cleanup_goals),$(goals)))
    $(error $(red)ERROR: The goals '$(cleanup_goals)' must not be used in conjunction with other targets!$(res))
  endif
endif

# reading configuration from project file and figure out bin directory, build directory and cache directory
include $(bin)build-configuration.mk
.PHONY : $(bin)build-configuration.mk
$(if $(build-configuration),,$(error $(red)ERROR: build-configuration.mk not included$(res)))

# A cleanup cleans all sub directories of the cache directory!
# Checking the header cache directory differs from dot directory.
ifeq ($(hcache),.)
  $(error $(red)ERROR: Header translation requires a header cache directory different from dot-directory!$(res))
endif

hcache_is_default ::=
ifeq ($(hcache),gcm.cache)
  hcache_is_default ::= 1
endif
$(call info_d,hcache_is_default='$(hcache_is_default)')

$(if $(hcache_is_default),\
  $(warning $(yel)WARNING: The header cache is the default directory:\
    The cache directory is moved away to avoid auto import during dependency scan.$(res))\
)

common_cache =
ifeq ($(mcache),$(hcache))
  common_cache = 1
endif

# Checking for valid configuration.
units ::= $(strip $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS))
$(if $(cleanup),,\
  $(if $(units),,\
    $(error $(red)ERROR: At least one header unit to translate is required!\
      (CXX_SYSTEM_HEADER_UNITS CXX_USER_HEADER_UNITS)$(res))\
  )\
)

# Getting the names for temporary configuration storage.
TMPDIR ?= /tmp
temp_header_units_list_name ::= $(TMPDIR)/$(subst /,_,$(CURDIR))_Makefile-header-units-header-units-list.tmp
temp_header_units_config_name ::= $(TMPDIR)/$(subst /,_,$(CURDIR))_Makefile-header-units-header-units-config.tmp

# Delete the stored Header Units list if the list has changed at start up.
# The file function avoids shell quoting issues. Write the temporary settings here and move in the recipe.
# The variable units is never empty, thus the comparison fails if '$(build_p)header-units-list' does not exist.
ifndef MAKE_RESTARTS
  ifeq ($(cleanup),)
    old_units ::= $(file < $(build_p)header-units-list)
    ifneq ($(units),$(old_units))
      $(call info_i,!Header Units list has changed!)
      $(file > $(temp_header_units_list_name),$(units))
      $(call info_i,$(shell $(RM) $(verbose) $(build_p)header-units-list))
    else
      $(call info_i,No changes in Header Units list.)
    endif
  endif
endif
$(call info_i,Registered System Header Units: $(CXX_SYSTEM_HEADER_UNITS))
$(call info_i,Registered User Header Units  : $(CXX_USER_HEADER_UNITS))

# A missing file triggers this rule and forces a complete re-build.
$(build_p)header-units-list : | $(build_ndot)
	$(due_to)
	mv $(verbose) '$(temp_header_units_list_name)' '$@'
	$(spacer)

# Delete the stored configuration file if the configuration has changed at start up.
# The variable units is never empty, thus the comparison fails if '$(build_p)header-units-list' does not exist.
configuration ::= '$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)'
ifndef MAKE_RESTARTS
  ifeq ($(cleanup),)
    old_configuration ::= $(file < $(build_p)header-units-config)
    ifneq ($(configuration),$(old_configuration))
      $(call info_i,!Header Units configuration has changed!$(nl))
      $(file > $(temp_header_units_config_name),$(configuration)) # file function avoids shell quoting issues
      $(call info_i,$(shell $(RM) $(verbose) $(build_p)header-units-config))
    else
      $(call info_i,No changes in Header Units configuration.$(nl))
    endif
  endif
endif

# A missing file triggers this rule and forces a complete re-build.
$(build_p)header-units-config : | $(build_ndot)
	$(due_to)
	mv $(verbose) '$(temp_header_units_config_name)' '$@'
	$(spacer)

# If a configuration change was encountered clean the header cache.
$(build_p)header-config-change-done : $(build_p)header-units-list $(build_p)header-units-config
	$(due_to)
# See comments in target clean.
	$(cmi_file_deletion)
	touch '$@'
	$(spacer)

# This compiler options make the cmi inclusion verbose.
infoflags =
ifneq ($(verbose),)
  infoflags = -flang-info-include-translate -flang-info-module-cmi
endif

# Stage 1: Generate the depfiles (*.dep).
# The depfile generation uses the default module mapper. If the header cache differs from 'gcm.cache' auto inclusion
# is effectively disabled. The default header cache directory is moved away during dependency scan.
depfiles_sys ::= $(addprefix $(build_p)system/,$(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS)))
$(call info_d,depfiles_sys='$(depfiles_sys)')
$(depfiles_sys) : $(build_p)system/%.dep : $(build_p)header-config-change-done
	$(due_to)
ifneq ($(hcache_is_default),)
# The move may fail for some jobs if parallel execution is enabled. Move is an atomic operation.
	$(ec)if [ -d 'gcm.cache' ]; then mv $(verbose) 'gcm.cache' 'gcm.cache.hidden' || :; fi
endif
	$(CXX) -x c++-system-header '$*' -c -M -MF '$@' -MQ '$@' -MP -Mno-modules $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(spacer)

depfiles_user ::= $(addprefix $(build_p)user/,$(addsuffix .dep,$(CXX_USER_HEADER_UNITS)))
$(call info_d,depfiles_user='$(depfiles_user)')
$(depfiles_user) : $(build_p)user/%.dep : $(build_p)header-config-change-done
	$(due_to)
ifneq ($(hcache_is_default),)
# The move may fail for some jobs if parallel execution is enabled. Move is an atomic operation.
	$(ec)if [ -d 'gcm.cache' ]; then mv $(verbose) 'gcm.cache' 'gcm.cache.hidden' || :; fi
endif
	$(CXX) -x c++-user-header '$*' -c -M -MF '$@' -MQ '$@' -MP -Mno-modules $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(spacer)
# The Order Only Prerequisites for the directories require secondary expansion and follow near makefile end.

# Stage 2: Generate header unit database and map file.
$(build_p)header-unit.dep $(build_p)header-map.modm &: $(depfiles_sys) $(depfiles_user)
	$(due_to)
	$(bin)header-map.sh '$(build_p)header-map.modm' '$(build_p)header-unit.dep' $(CURDIR) '$(build_p)system' '$(build_p)user' '.dep' '$(hcache)' '.gcm' $^
# Restore the cache directory.
ifneq ($(hcache_is_default),)
	$(ec)if [ -d 'gcm.cache.hidden' ]; then \
	  if [ -d 'gcm.cache' ]; then \
	    echo 'ERROR: Something went wrong! Cleanup' >&2; false; \
	  else \
	    mv $(verbose) 'gcm.cache.hidden' 'gcm.cache'; \
	  fi \
	fi
endif
	$(spacer)

# Stage 2d: Generate the module dep files.
# The content of the mapper file only changes if the configuration has changed. So
# we can make the mapper file a order only prerequisite.
depfiles_m_sys ::= $(addprefix $(build_p)system/,$(addsuffix .m.dep,$(CXX_SYSTEM_HEADER_UNITS)))
$(call info_d,depfiles_m_sys='$(depfiles_m_sys)')
$(depfiles_m_sys) : $(build_p)system/%.m.dep : $(build_p)system/%.dep | $(build_p)header-map.modm
	$(due_to)
	$(bin)header-dep.sh $(build_p)header-map.modm '$<' $(CURDIR) '$@'
	$(spacer)

depfiles_m_user ::= $(addprefix $(build_p)user/,$(addsuffix .m.dep,$(CXX_USER_HEADER_UNITS)))
$(call info_d,depfiles_m_user='$(depfiles_m_user)')
$(depfiles_m_user) : $(build_p)user/%.m.dep : $(build_p)user/%.dep | $(build_p)header-map.modm
	$(due_to)
	$(bin)header-dep.sh $(build_p)header-map.modm '$<' $(CURDIR) '$@'
	$(spacer)

# Stage 3: cmi file generation:
# Automatic header inclusion is effective since make maintains the the order of depended builds.
# The directory of a cmi file is never the dot directory so we can the directory in the Order Only
# Prerequisite without a dot check.

# include information about source names
CXX_KIND_UNIT_SRC_MOD_CMI_LIST ::=
ifeq ($(cleanup),)
  include $(depfiles_sys) $(depfiles_user)
  include $(build_p)header-unit.dep
  include $(depfiles_m_sys) $(depfiles_m_user)
endif

# pp_list - pretty print list
pp_list = $(foreach var,$1,$(tab)$(var)$(nl))
$(call info_d,$(nl)CXX_KIND_UNIT_SRC_MOD_CMI_LIST =$(nl)$(call pp_list,$(CXX_KIND_UNIT_SRC_MOD_CMI_LIST)))

# The mapper option for cmi file generation.
hmapper_opt ::= $(if $(hcache_is_default),,-fmodule-mapper=$(build_p)header-map.modm)

# The rule template for unit cmi file targets.
define cmi_file_rule
  $(call info_d,Header Unit Rule$(nl)$(tab)$(cmi) : $(src) $(build_p)$(kind)/$(unit).dep | $(patsubst %/,%,$(dir $(cmi))))

  $$(cmi) : my_unit ::= $$(unit)
  $$(cmi) : $$(src) $$(build_p)$$(kind)/$$(unit).dep | $$(patsubst %/,%,$$(dir $$(cmi)))
	$$(due_to)
	$$(CXX) -x c++-$(kind)-header $$(my_unit) -c $$(hmapper_opt) $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) $$(infoflags)
	$(spacer)
endef

# Evaluating the information from CXX_KIND_UNIT_SRC_MOD_CMI_LIST and generate the rules for unit cmi files.
cmifiles ::=
ifeq ($(strip $(CXX_KIND_UNIT_SRC_MOD_CMI_LIST)),)
  $(call info_d,No header database!)
endif
$(foreach line,$(CXX_KIND_UNIT_SRC_MOD_CMI_LIST),\
  $(let kind unit src mod cmi,$(subst ;, ,$(line)),\
      $(eval cmifiles += $(cmi))\
      $(eval $(cmi_file_rule))\
  )\
)
$(call info_d,$(nl)cmifiles = '$(cmifiles)')


# Stage 5: Make the final header part of module map to be used by the main script.
$(build_p)module-map-h.txt : $(cmifiles) | $(build_ndot)
	$(due_to)
	$(ec)grep --invert-match '$$root' '$(build_p)header-map.modm' > '$@'
	$(call echo_i,Header Units translation complete.)
	$(spacer)

.PHONY : all_
all_ : $(build_p)module-map-h.txt

# The canned recipe for header unit cmi file deletion:
cmi_file_deletion = LIST=; for x in $(hcache_p)*; do if [[ -d "$${x}" ]]; then LIST+=" $${x}"; fi; done;\
  $(RMDIR) $(verbose) $${LIST};

# Cleanup rules:
.PHONY : clean
clean :
	$(call echo_i,Clean header units ...)
	$(RM) $(verbose) $(build_p)module-map-h.txt
# Header cleanup deletes all sub directories of the header cache. In case of Simple Mapping and Common Cache,
# module cmi files may be also affected. This should not be a problem since a header cleanup always implies a
# module cleanup.
	$(cmi_file_deletion)
	$(RM) -r $(verbose) $(build_p)user/* $(build_p)system/*
	$(RM) $(verbose) $(build_p)header-map.modm $(build_p)header-unit.dep $(build_p)header-config-change-done
	$(RMDIR) $(verbose) 'gcm.cache.hidden'
	$(spacer)

.PHONY : purge
purge : clean
	$(call echo_i,Purge header units...)
	$(RMDIR) $(verbose) $(build_p)user $(build_p)system
ifeq ($(common_cache),)
# Header translation requires a header cache directory different from dot-directory.
	$(RMDIR) $(verbose) $(hcache_ndot)
endif
	$(RM) $(verbose) $(build_p)header-units-config $(temp_header_units_config_name)
	$(RM) $(verbose) $(build_p)header-units-list $(temp_header_units_list_name)
	$(spacer)

.SECONDEXPANSION :

$(call info_d,)

# Appending the Order Only Prerequisites for the buil dfile directories.
# The infofiles are never in . dir, thus the variable $(@D) can be used as is.
$(depfiles_sys) : | $$(@D)
$(depfiles_user) : | $$(@D)

# Creating rules for all 'depfiles' directories:
all_build_dirs ::= $(sort $(dir $(depfiles_sys) $(depfiles_user)))
$(call info_d,all_build_dirs = $(all_build_dirs))
# Note: all_build_dirs includes the trailing slash.

# Getting the unique list of directory parts with trailing slash removed.
all_build_dir_parts ::= $(patsubst %/,%,$(sort $(foreach path,$(all_build_dirs),$(call all_dirs,$(path)))))
$(call info_d,all_build_dir_parts = '$(all_build_dir_parts)')

$(all_build_dir_parts) : % : | $$(@D)
	$(run_tgt)
	$(MKDIR) $(verbose) '$@'
	$(spacer)

# Creating rules for all cmi files:
all_cmi_dirs ::= $(sort $(dir $(cmifiles)))
$(call info_d,all_cmi_dirs = '$(all_cmi_dirs)')
# Note: all_cmi_dirs includes the trailing slash.

# Getting the unique list of directory parts with trailing slash removed.
all_cmi_dir_parts ::= $(patsubst %/,%,$(sort $(foreach path,$(all_cmi_dirs),$(call all_dirs,$(path)))))
$(call info_d,all_cmi_dir_parts = '$(all_cmi_dir_parts)')

$(all_cmi_dir_parts) : % : | $$(@D)
	$(run_tgt)
# MKDIR may fail to create the dot components of the cmi file name!
	-$(MKDIR) $(verbose) '$@'
	$(spacer)

$(call info_i,**** END reading makefile $(this_makefile).$(nl))
