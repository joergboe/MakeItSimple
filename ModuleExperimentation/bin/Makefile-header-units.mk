# Makefile translates System Header Units and User Header Units
#
# This script requires two variables with the list of header units to translate
# CXX_SYSTEM_HEADER_UNITS and CXX_USER_HEADER_UNITS.
#
# Stage 1 determines the header unit to source and cmi file mapping. This rule fires only once at start-up or after a
# configuration change. (The infofiles '%.depn' contain the variable CXX_UNIT_SRC_MOD_CMI_KIND_LIST)
#
# Stage 2 generates a module mapper file for the header units. (header-map.modm)
#
# Stage 3 determines the dependency tree for all header unit cmi files. A script scans the dependencies of a header unit
# (the first rule). If a particular dependency exists in the system header or user header database, a rule with the
# dependent cmi file is added. (depfiles '%.dep')
#
# Stage 4 translates header unit source files to cmi files. The depfile substitutes all header dependencies of the
# cmi file.
#
# Stage 5 makes the final header part of the module map 'module-map-h.modm' to be used by the main script.
#
# Relative header file locations are considered relative to the current directory.
#
# Intermediate build artifacts are stored in directories 'system' and 'user'.
# The files 'header-units-list', 'header-units-config', 'header-map.modm' and 'module-map-h.modm' are stored in
# current directory.

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
include $(bin)definitions.mk
# do not try update definitions.mk
.PHONY : $(bin)definitions.mk
$(if $(definitions),,$(error $(red)ERROR: $(bin)definitions.mk not included$(res)))

# remove all the built-in pattern rules
MAKEFLAGS += -r

# global settings
SHELL = /bin/bash
.SHELLFLAGS ::= -ec
RMDIR = rm -rf
MKDIR = mkdir
RM = rm -f
.DELETE_ON_ERROR:

# default target
.PHONY : all
all : all_

# do not try update this makefile
$(bin)Makefile-header-units.mk : ;

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
include $(bin)segment-build-configuration.mk
.PHONY : $(bin)segment-build-configuration.mk
$(if $(segment-build-configuration),,$(error $(red)ERROR: segment-build-configuration.mk not included$(res)))

# checking header cache directory
ifeq ($(hcache),.)
  $(error $(red)ERROR: Header translation requires a header cache directory different from dot-directory!$(res))
endif

common_cache =
ifeq ($(mcache),$(hcache))
  common_cache = 1
endif

ifneq ($(common_cache),)
  define warning_text
If the header cache and module cache are equal, auto import may happen in the dependency scan or even in the info scan.
This may be a problem if old and dispensable files are present in the cache. Thus make a complete cleanup before
header list changes.
  endef
  $(warning $(yel)WARNING: Header cache and module cache are equal.$(nl)$(warning_text)$(res))

  ifneq ($(CXX_SIMPLE_MAPPING),)
    $(warning $(yel)WARNING: If Simple Mapping and Common Cache is used a module cleanup may clean also some user\
    header cmi files!$(res))
  endif
endif

# checking build directory
ifneq ($(build),.)
  ifeq ($(wildcard $(build)),)
    $(warning $(yel)WARNING: Build directory '$(build)' does not exist.$(res))
    $(call info_i,$(shell $(MKDIR) $(verbose) $(build)))
  endif
endif

# Delete the stored Header Units list if the list has changed at start up.
# The file function avoids shell quoting issues. Write the settings here and move in the recipe.
units ::= $(strip $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS))
ifndef MAKE_RESTARTS
  ifeq ($(cleanup),)
    old_units ::= $(file < $(build_p)header-units-list)
    ifneq ($(units),$(old_units))
      $(call info_i,!Header Units list has changed!)
      $(file > $(build_p)header-units-list.temp,$(units))
      $(call info_i,$(shell $(RM) $(verbose) $(build_p)header-units-list))
    else
      $(call info_i,No changes in Header Units list.)
    endif
  endif
endif

$(call info_i,Registered System Header Units: $(CXX_SYSTEM_HEADER_UNITS))
$(call info_i,Registered User Header Units  : $(CXX_USER_HEADER_UNITS))

# A missing file triggers this rule.
$(build_p)header-units-list :
	$(due_to)
	mv $(verbose) $(build_p)header-units-list.temp $@
	$(spacer)

# Delete the stored configuration file if the configuration has changed at start up.
configuration ::= $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
ifndef MAKE_RESTARTS
  ifeq ($(cleanup),)
    old_configuration ::= $(file < $(build_p)header-units-config)
    ifneq ($(configuration),$(old_configuration))
      $(call info_i,!Header Units configuration has changed!$(nl))
      $(file > $(build_p)header-units-config.temp,$(configuration)) # file function avoids shell quoting issues
      $(call info_i,$(shell $(RM) $(verbose) $(build_p)header-units-config))
    else
      $(call info_i,No changes in Header Units configuration.$(nl))
    endif
  endif
endif

# A missing configuration file triggers this rule.
$(build_p)header-units-config :
	$(due_to)
	mv $(verbose) $(build_p)header-units-config.temp $@
	$(spacer)

# Stage 1: Generate infofiles.
# The source file name is figured out from script get-header-info-and-map.sh and the cmi file name is constructed.
# Output : CXX_UNIT_SRC_MOD_CMI_KIND_LIST
# Source file may be relative to the current directory or absolute.
infofiles_sys ::= $(addprefix $(build_p)system/,$(addsuffix .depn,$(CXX_SYSTEM_HEADER_UNITS)))
$(infofiles_sys) : $(build_p)system/%.depn: $(build_p)header-units-list $(build_p)header-units-config
	$(due_to)
	$(CXX) -x c++-system-header $* -c -MM -MF $(build_p)system/$*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${bin}get-header-info-and-map.sh $(build_p)system/$*.dep.0 $@ $* $(hcache) gcm system
	$(spacer)

infofiles_user ::= $(addprefix $(build_p)user/,$(addsuffix .depn,$(CXX_USER_HEADER_UNITS)))
$(infofiles_user) : $(build_p)user/%.depn: $(build_p)header-units-list $(build_p)header-units-config
	$(due_to)
	$(CXX) -x c++-user-header $* -c -MM -MF $(build_p)user/$*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${bin}get-header-info-and-map.sh $(build_p)user/$*.dep.0 $@ $* $(hcache) gcm user
	$(spacer)
# The Order Only Prerequisites for the directories require secondary expansion and follow near makefile end.

# Stage 2: Generate database cmi mapper: <logical name> <cmi>
$(build_p)header-map.modm : $(infofiles_sys) $(infofiles_user)
	$(due_to)
	$(ec)echo '$$root .' > '$@'; \
    cat $^ | { IFS=\;; while read -r -a ar; do echo "$${ar[2]//\$$\$$/\$$} $${ar[3]//\$$\$$/\$$}"; done; } >> '$@'
	$(spacer)

# compiler options to make the cmi inclusion verbose
infoflags =
ifneq ($(verbose),)
  infoflags = -flang-info-include-translate -flang-info-module-cmi
endif

# Stage 3: Generate the depfiles
depfiles_sys ::= $(addprefix $(build_p)system/,$(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS)))
$(depfiles_sys) : $(build_p)system/%.dep : $(build_p)header-map.modm
	$(due_to)
	$(CXX) -x c++-system-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$(build_p)system/$*.o \
 -fdeps-file=$(build_p)system/$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	${bin}add-header-module-dep.sh $(build_p)header-map.modm $(CURDIR) $@.1 $@
	$(spacer)

depfiles_user ::= $(addprefix $(build_p)user/,$(addsuffix .dep,$(CXX_USER_HEADER_UNITS)))
$(depfiles_user) : $(build_p)user/%.dep : $(build_p)header-map.modm
	$(due_to)
	$(CXX) -x c++-user-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$(build_p)user/$*.o \
 -fdeps-file=$(build_p)user/$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	${bin}add-header-module-dep.sh $(build_p)header-map.modm $(CURDIR) $@.1 $@
	$(spacer)


# Stage 4: cmi file generation
# rule template for unit cmi file targets
# automatic header inclusion is effective
# The directory of a cmi file is never the dot directory.

# mapper option
hmapper_opt = $(if $(user_mapping),-fmodule-mapper=$(build_p)header-map.modm)

define cmi_file_rule
  $(call info_i,Header Unit Rule$(nl)$(tab)$(cmi) : $(src) $(build_p)$(kind)/$(unit).dep | $(patsubst %/,%,$(dir $(cmi))))

  $$(cmi) : my_unit ::= $$(unit)
  $$(cmi) : $$(src) $$(build_p)$$(kind)/$$(unit).dep | $$(patsubst %/,%,$$(dir $$(cmi)))
	$$(due_to)
	$$(CXX) -x c++-$(kind)-header $$(my_unit) -c $$(hmapper_opt) $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) $$(infoflags)
	$(spacer)
endef

# include information about source names
CXX_UNIT_SRC_MOD_CMI_KIND_LIST ::=
ifeq ($(cleanup),)
  include $(infofiles_sys) $(infofiles_user)
endif
# pp_list - pretty print list
pp_list = $(foreach var,$1,$(tab)$(var)$(nl))
$(call info_d,$(nl)CXX_UNIT_SRC_MOD_CMI_KIND_LIST =$(nl)$(call pp_list,$(CXX_UNIT_SRC_MOD_CMI_KIND_LIST)))

# evaluate information from infofiles and generate:
# rules for unit cmi files
cmifiles ::=
ifeq ($(strip $(CXX_UNIT_SRC_MOD_CMI_KIND_LIST)),)
  $(call info_i,No header database!)
endif
$(foreach line,$(CXX_UNIT_SRC_MOD_CMI_KIND_LIST),\
  $(let unit src mod cmi kind,$(subst ;, ,$(line)),\
      $(eval cmifiles += $(cmi))\
      $(eval $(cmi_file_rule))\
  )\
)
$(call info_i,$(nl)cmifiles = '$(cmifiles)')

# include the depfile rules
ifeq ($(cleanup),)
  include $(depfiles_sys) $(depfiles_user)
endif

# Stage 5: Make the final header part of module map to be used by the main script.
$(build_p)module-map-h.modm : $(cmifiles)
	$(due_to)
	$(ec)cp $(verbose) '$(build_p)header-map.modm' '$@'
	$(call echo_i,Header Units translation complete.)
	$(spacer)

.PHONY : all_
all_ : $(build_p)module-map-h.modm

# cleanup
.PHONY : clean
clean :
	$(call echo_i,Clean header units ...)
	$(RM) $(verbose) $(build_p)module-map-h.modm
# Header cleanup deletes all sub directories of the header cache. In case of Simple Mapping and Common Cache,
# module cmi files may be also affected. This should not be a problem since a header cleanup always implies a
# module cleanup.
	LIST=; for x in $(hcache_p)*; do if [[ -d "$${x}" ]]; then LIST+=" $${x}"; fi; done; \
 $(RMDIR) $(verbose) $${LIST};
	$(RM) -r $(verbose) $(build_p)user/* $(build_p)system/*
	$(RM) $(verbose) $(build_p)header-map.modm
	$(spacer)

.PHONY : purge
purge : clean
	$(call echo_i,Purge header units...)
	$(RMDIR) $(verbose) $(build_p)user $(build_p)system
ifeq ($(common_cache),)
# Header translation requires a header cache directory different from dot-directory.
	$(RMDIR) $(verbose) $(hcache_ndot)
endif
	$(RM) $(verbose) $(build_p)header-units-config $(build_p)header-units-config.temp
	$(RM) $(verbose) $(build_p)header-units-list $(build_p)header-units-list.temp
	$(spacer)

.SECONDEXPANSION :

$(call info_d,)

# appending the Order Only Prerequisites for the infofile directories
# The infofiles are never in . dir.
$(infofiles_sys) : | $$(@D)
$(infofiles_user) : | $$(@D)

# infofiles directory rules
dirs_infofiles ::= $(sort $(dir $(infofiles_sys) $(infofiles_user)))
$(call info_d,dirs_infofiles = $(dirs_infofiles))
# the unique list of directory parts with trailing slash removed
all_infofiles_dir_parts ::= $(patsubst %/,%,$(sort $(foreach path,$(dirs_infofiles),$(call all_dirs,$(path)))))
$(call info_d,all_infofiles_dir_parts = '$(all_infofiles_dir_parts)')

$(all_infofiles_dir_parts) : % : | $$(@D)
	$(run_tgt)
	$(MKDIR) $(verbose) '$@'
	$(spacer)

# cmi directory rules - dir function has always a trailing slash
dirs_cmi_files ::= $(sort $(dir $(cmifiles)))
$(call info_d,dirs_cmi_files = '$(dirs_cmi_files)')
all_cmi_dirs_parts ::= $(patsubst %/,%,$(sort $(foreach path,$(dirs_cmi_files),$(call all_dirs,$(path)))))
$(call info_d,all_cmi_dirs_parts = '$(all_cmi_dirs_parts)')

$(all_cmi_dirs_parts) : % : | $$(@D)
	$(run_tgt)
# MKDIR may fail to create the dot components of the cmi file name!
	-$(MKDIR) $(verbose) '$@'
	$(spacer)

$(call info_i,**** END reading makefile $(this_makefile).$(nl))
