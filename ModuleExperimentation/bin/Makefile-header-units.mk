# Makefile translates System Header Units and User Header Units
#
# This script requires two variables with the list of header units to translate
# CXX_SYSTEM_HEADER_UNITS and CXX_USER_HEADER_UNITS.
#
# Stage 1 determines the header unit to source and cmi file mapping. This rule fires only once at start-up or after a
# configuration change. (The infofiles '%.depn' contain the variable CXX_UNIT_SRC_MOD_CMI_KIND_LIST)
#
# Stage 2 generates a module mapper file for the header units. (header-mapper.txt)
#
# Stage 3 determines the dependency tree for all header unit cmi files. A script scans the dependencies of a header unit
# (the first rule). If a particular dependency exists in the system header or user header database, a rule with the
# dependent cmi file is added. (depfiles '%.dep')
#
# Stage 4 translates header unit source files to cmi files. The depfile substitutes all header dependencies of the
# cmi file.
#
# Stage 5 make a final cmi files list. ('header-cmis.txt')
#
# Relative header file locations are considered relative to the current directory.
#
# Intermediate build artifacts are stored in directories 'system' and 'user'.
# The files 'header-units-list', 'header-units-config', 'header-mapper.txt' and 'header-cmis.txt' are stored in
# current directory.

# get path of this makefile
this_makefile ::= $(lastword $(MAKEFILE_LIST))
bin ::= $(dir $(this_makefile))

# including functions and variables
include $(bin)segment1.mk
.PHONY : $(bin)segment1.mk
$(if $(segment1),,$(error ERROR: segment1.mk not included))

# intro
$(call info_i,$(nl)$(if $(MAKE_RESTARTS),RESTART # $(MAKE_RESTARTS),START) $(this_makefile) in $(CURDIR).$(nl))

# global settings
SHELL = /bin/bash
.SHELLFLAGS ::= -ec
RMDIR = rm -rf
MKDIR = mkdir
RM = rm -f
# remove all the built-in pattern rules
MAKEFLAGS += -r
.DELETE_ON_ERROR:

# default target
.PHONY : all
all : all_

# do not try update makefiles
$(bin)Makefile-header-units.mk : ;

# check goals
cleanup_goals = clean purge
goals = $(MAKECMDGOALS)
# The variable cleanup is also used to prevent inclusion of dependent makefiles.
cleanup ::= $(filter $(cleanup_goals),$(goals))
ifneq ($(cleanup),)
  ifneq (,$(filter-out $(cleanup_goals),$(goals)))
    $(error ERROR: The goals '$(cleanup_goals)' must not be used in conjunction with other targets!)
  endif
endif

# reading configuration from project file and figure out bin directory, build directory and cache directory
include $(bin)segment-build-configuration.mk
.PHONY : $(bin)segment-build-configuration.mk
$(if $(segment-build-configuration),,$(error ERROR: segment-build-configuration.mk not included))

# module cache directory
ifeq ($(hcache_res),.)
  $(error ERROR: Header translation requires a header cache directory different from dot-directory!)
endif

common_cache ::=
ifeq ($(cache_res),$(hcache_res))
  common_cache ::= 1
endif

ifneq ($(common_cache),)
  define warning_text
If the header cache and module cache are equal, auto import may happen in the dependency scan or even in the info scan.
This may be a problem if old and dispensable files are present in the cache. Thus make a complete cleanup before
header list changes.
  endef
  $(warning WARNING: Header cache and module cache are equal.$(nl)$(warning_text))

  ifneq ($(CXX_SIMPLE_MAPPING),)
    $(error ERROR: Simple module mapping requires a separate header cache directory!)
  endif
endif


# compiler options to make the cmi inclusion verbose
infoflags =
ifneq ($(verbose),)
  infoflags = -flang-info-include-translate -flang-info-module-cmi
endif

# Delete the stored Header Units list if the list has changed at start up.
units ::= $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS)
ifndef MAKE_RESTARTS
  ifeq ($(cleanup),)
    old_units ::= $(file < $(buildp)header-units-list)
    ifneq ($(units),$(old_units))
      $(call info_i,!Header Units list has changed!)
      $(file > $(buildp)header-units-list.temp,$(units)) # file function avoids shell quoting issues
      $(shell rm -f $(buildp)header-units-list)
    else
      $(call info_i,No changes in Header Units list.)
    endif
  endif
endif

$(call info_i,Registered System Header Units: $(CXX_SYSTEM_HEADER_UNITS))
$(call info_i,Registered User Header Units  : $(CXX_USER_HEADER_UNITS))

# A missing file triggers this rule.
$(buildp)header-units-list :
	$(due_to)
	$(ec)mv $(verbose) $(buildp)header-units-list.temp $@
	$(spacer)

# Delete the stored configuration file if the configuration has changed at start up.
configuration ::= $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
ifndef MAKE_RESTARTS
  ifeq ($(cleanup),)
    old_configuration ::= $(file < $(buildp)header-units-config)
    ifneq ($(configuration),$(old_configuration))
      $(call info_i,!Header Units configuration has changed!$(nl))
      $(file > $(buildp)header-units-config.temp,$(configuration)) # file function avoids shell quoting issues
      $(shell rm -f $(buildp)header-units-config)
    else
      $(call info_i,No changes in Header Units configuration.$(nl))
    endif
  endif
endif

# A missing configuration file triggers this rule.
$(buildp)header-units-config :
	$(due_to)
	$(ec)mv $(verbose) $(buildp)header-units-config.temp $@
	$(spacer)

# Stage 1: Generate infofiles.
# The source file name is figured out from script get-header-info-and-map.sh and the cmi file name is constructed.
# Output : CXX_UNIT_SRC_MOD_CMI_KIND_LIST
# Source file may be relative to the current directory or absolute.
infofiles_sys ::= $(addprefix $(buildp)system/,$(addsuffix .depn,$(CXX_SYSTEM_HEADER_UNITS)))
$(infofiles_sys) : $(buildp)system/%.depn: $(buildp)header-units-list $(buildp)header-units-config
	$(due_to)
	$(ec)$(CXX) -x c++-system-header $* -c -MM -MF $(buildp)system/$*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(ec)${bin}get-header-info-and-map.sh $(buildp)system/$*.dep.0 $@ $* $(hcache_res) gcm system
	$(spacer)

infofiles_user ::= $(addprefix $(buildp)user/,$(addsuffix .depn,$(CXX_USER_HEADER_UNITS)))
$(infofiles_user) : $(buildp)user/%.depn: $(buildp)header-units-list $(buildp)header-units-config
	$(due_to)
	$(ec)$(CXX) -x c++-user-header $* -c -MM -MF $(buildp)user/$*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(ec)${bin}get-header-info-and-map.sh $(buildp)user/$*.dep.0 $@ $* $(hcache_res) gcm user
	$(spacer)
# The Order Only Prerequisites for the directories require secondary expansion and follow near makefile end.

# Function: Get the directory, filter out dot dirs and remove trailing slash.
dir_but_not_dot_dir = $(patsubst %/,%,$(filter-out ./,$(dir $1)))

# rules for the infofiles directories
dirs_infofiles_sys ::= $(sort $(call dir_but_not_dot_dir,$(infofiles_sys)))
$(call info_d,Directories for infofiles_sys = $(dirs_infofiles_sys))
$(dirs_infofiles_sys) : | $(buildp)system
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

dirs_infofiles_user ::= $(sort $(call dir_but_not_dot_dir,$(infofiles_user)))
$(call info_d,Directories for infofiles_user = $(dirs_infofiles_user))
$(dirs_infofiles_user) : | $(buildp)user
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

$(buildp)system :
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

$(buildp)user :
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

# Stage 2: Generate database cmi mapper: <logical name> <cmi>
$(buildp)header-mapper.txt : $(infofiles_sys) $(infofiles_user)
	$(due_to)
	$(ec)cat $^ | { IFS=\;; while read -r -a ar; do echo "$${ar[2]//\$$\$$/\$$} $${ar[3]//\$$\$$/\$$}"; done; } > "$@"
	$(spacer)

# Stage 3: Generate the depfiles
depfiles_sys ::= $(addprefix $(buildp)system/,$(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS)))
$(depfiles_sys) : $(buildp)system/%.dep : $(buildp)header-mapper.txt
	$(due_to)
	$(ec)$(CXX) -x c++-system-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$(buildp)system/$*.o \
 -fdeps-file=$(buildp)system/$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(ec)${bin}add-header-module-dep.sh $(buildp)header-mapper.txt $(CURDIR) $@.1 $@
	$(spacer)

depfiles_user ::= $(addprefix $(buildp)user/,$(addsuffix .dep,$(CXX_USER_HEADER_UNITS)))
$(depfiles_user) : $(buildp)user/%.dep : $(buildp)header-mapper.txt
	$(due_to)
	$(ec)$(CXX) -x c++-user-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$(buildp)user/$*.o \
 -fdeps-file=$(buildp)user/$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(ec)${bin}add-header-module-dep.sh $(buildp)header-mapper.txt $(CURDIR) $@.1 $@
	$(spacer)

# Stage 4: cmi file generation
# rule template for unit cmi file targets
# automatic header inclusion is effective
define cmi_file_rule
  $(info generate $(unit) rule : $(cmi) : $(src) $(buildp)$(kind)/$(unit).dep)

  $$(cmi) : my_unit ::= $$(unit)
  $$(cmi) : $$(src) $$(buildp)$$(kind)/$$(unit).dep
	$$(due_to)
	$(ec)$$(CXX) -x c++-$(kind)-header $$(my_unit) -c -fmodule-mapper=$$(buildp)header-mapper.txt $$(CXXFLAGS) \
 $$(CPPFLAGS) $$(TARGET_ARCH) $$(infoflags)
	$(spacer)
endef

# include information about source names
CXX_UNIT_SRC_MOD_CMI_KIND_LIST ::=
ifeq ($(cleanup),)
  include $(infofiles_sys) $(infofiles_user)
endif
$(call info_d,CXX_UNIT_SRC_MOD_CMI_KIND_LIST = $(CXX_UNIT_SRC_MOD_CMI_KIND_LIST))

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
$(call info_i,cmifiles = '$(cmifiles)')

# include the depfile rules
ifeq ($(cleanup),)
  include $(depfiles_sys) $(depfiles_user)
endif

# Stage 5: Make a final list of cmi file names.
$(buildp)header-cmis.txt : $(cmifiles)
	$(due_to)
	$(ec)for x in $^; do echo "$$x"; done > $@
	$(call echo_i,Header Units translation complete.)
	$(spacer)

.PHONY : all_
all_ : $(buildp)header-cmis.txt

# cleanup
.PHONY : clean
clean :
	$(call echo_i,Clean header units ...)
	$(ec)$(RM) $(verbose) $(buildp)header-cmis.txt
# Header cleanup deletes all sub directories of the header cache. Simple mapping requires a separate hcache.
	$(ec)LIST=; for x in $(hcachep)*; do if [[ -d "$${x}" ]]; then LIST+=" $${x}"; fi; done; \
 $(RMDIR) $(verbose) $${LIST};
	$(ec)$(RM) $(verbose) $(buildp)user/* $(buildp)system/*
	$(ec)$(RM) $(verbose) $(buildp)header-mapper.txt
	$(spacer)

.PHONY : purge
purge : clean
	$(call echo_i,Purge header units...)
	$(ec)$(RMDIR) $(verbose) $(buildp)user $(buildp)system
ifeq ($(common_cache),)
# Header translation requires a header cache directory different from dot-directory.
	$(ec)$(RMDIR) $(verbose) $(hcache_ndot)
endif
	$(ec)$(RM) $(verbose) $(buildp)header-units-config $(buildp)header-units-config.temp
	$(ec)$(RM) $(verbose) $(buildp)header-units-list $(buildp)header-units-list.temp
	$(spacer)

# Append the Order Only Prerequisites for the infofile directories:

# Get the directory part of the target but skip pure . pattern.
target_dir_but_not_dot_dir = $(subst .,,$(@D))

.SECONDEXPANSION :

$(infofiles_sys) : | $$(target_dir_but_not_dot_dir)
$(infofiles_user) : | $$(target_dir_but_not_dot_dir)

$(call info_i,END reading makefile $(this_makefile).$(nl))
