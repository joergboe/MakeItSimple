# Makefile translates System Header Units and User Header Units

# Stage 1: gets the Unit to Source mapping. This rule fires only once at start-up or after a configuration change.

# Stage 2: gets the dependency tree for all Header Units and substitute the Header File of a registered Header Unit with
#          the cmi file name of that Unit.

# Stage 3: translates Header Units.

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) $(this_makefile) in directory $(CURDIR))

# get path of this makefile
my_bin_dir ::= $(dir $(lastword $(MAKEFILE_LIST)))

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
.PHONY : all
all : header-cmis.txt

# project definitions
PROJECT_MK ?= project.mk
include $(PROJECT_MK)

# required compiler options
CXXFLAGS ?= -std=c++20 -fmodules
CXXFLAGS += -flang-info-include-translate -flang-info-module-cmi

# module cache directory
# If the cache is the default directory, a auto import may happen in the dependency scan or even in the info scan.
# This may be a problem if old and dispensable files are present. Thus make a cleanup before header list changes.
CXX_MODULE_CACHE ?= gcm.cache

# Delete the stored Header Units list if the list has changed at start up.
units ::= $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS)
ifndef MAKE_RESTARTS
  old_units ::= $(file < header-units-list)
  ifneq ($(units),$(old_units))
    $(info !Header Units list has changed!)
    $(file > header-units-list.temp,$(units)) # file function avoids shell quoting issues
    $(shell rm -f header-units-list)
  else
    $(info No changes in Header Units list.)
  endif
endif

$(info Registered System Header Units: $(CXX_SYSTEM_HEADER_UNITS))
$(info Registered User Header Units  : $(CXX_USER_HEADER_UNITS))
$(info )

# A missing file triggers this rule.
header-units-list :
	$(due_to)
	mv header-units-list.temp $@
	@echo

# Delete the stored configuration file if the configuration has changed at start up.
configuration ::= $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
ifndef MAKE_RESTARTS
  old_configuration ::= $(file < header-units-config)
  ifneq ($(configuration),$(old_configuration))
    $(info !Header Units configuration has changed!)
    $(file > header-units-config.temp,$(configuration)) # file function avoids shell quoting issues
    $(shell rm -f header-units-config)
  else
    $(info No changes in Header Units configuration.)
  endif
  $(info )
endif

# A missing configuration file triggers this rule.
header-units-config :
	$(due_to)
	mv header-units-config.temp $@
	@echo

# Generate infofiles : The source file name is figured out from script dep_2src.sh and the cmi file name is constructed.
# Output : CXX_UNIT_SRC_MOD_CMI_KIND_LIST
# Source file may be relative or absolute.
infofiles_sys ::= $(addprefix system/,$(addsuffix .dep.n,$(CXX_SYSTEM_HEADER_UNITS)))
$(infofiles_sys) : system/%.dep.n: header-units-list header-units-config
	$(due_to)
	$(CXX) -x c++-system-header $* -c -MM -MF system/$*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}get-header-info-and-map.sh system/$*.dep.0 $@ $* $(CXX_MODULE_CACHE) gcm system # provide variable CXX_UNIT_SRC_CMI_LIST
	@echo

infofiles_user ::= $(addprefix user/,$(addsuffix .dep.n,$(CXX_USER_HEADER_UNITS)))
$(infofiles_user) : user/%.dep.n: header-units-list header-units-config
	$(due_to)
	$(CXX) -x c++-user-header $* -c -MM -MF user/$*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}get-header-info-and-map.sh user/$*.dep.0 $@ $* $(CXX_MODULE_CACHE) gcm user # provide variable CXX_UNIT_SRC_CMI_LIST
	@echo

# The Order Only Prerequisites for the directories require secondary expansion and follow near makefile end.

# Function: Get the directory, filter out dot dirs and remove trailing slash.
dir_but_not_dot_dir = $(patsubst %/,%,$(filter-out ./,$(dir $1)))

# rules for the infofiles directories
dirs_infofiles_sys ::= $(sort $(call dir_but_not_dot_dir,$(infofiles_sys)))
$(info Directories for infofiles_sys = $(dirs_infofiles_sys))
$(dirs_infofiles_sys) :
	mkdir -p $@
	@echo

dirs_infofiles_user ::= $(sort $(call dir_but_not_dot_dir,$(infofiles_user)))
$(info Directories for infofiles_user = $(dirs_infofiles_user))
$(dirs_infofiles_user) :
	mkdir -p $@
	@echo

# generate database cmi mapper: <logical name> <cmi>
header-mapper.txt : $(infofiles_sys) $(infofiles_user)
	$(due_to)
	@cat $^ | { IFS=\;; while read -r -a ar; do echo "$${ar[2]//\$$\$$/\$$} $${ar[3]//\$$\$$/\$$}"; done; } > "$@"
	@echo

# generate the depfiles
depfiles_sys ::= $(addprefix system/,$(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS)))
$(depfiles_sys) : system/%.dep : header-mapper.txt
	$(due_to)
	$(CXX) -x c++-system-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=system/$*.o \
 -fdeps-file=system/$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}add-header-module-dep.sh header-mapper.txt $(CURDIR) $@.1 $@
	@echo

depfiles_user ::= $(addprefix user/,$(addsuffix .dep,$(CXX_USER_HEADER_UNITS)))
$(depfiles_user) : user/%.dep : header-mapper.txt
	$(due_to)
	$(CXX) -x c++-user-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=user/$*.o \
 -fdeps-file=user/$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}add-header-module-dep.sh header-mapper.txt $(CURDIR) $@.1 $@
	@echo

# rule template for unit cmi file targets
# automatic header inclusion is effective
define cmi_file_rule
  $(info generate $(unit) rule : $(cmi) : $(src) $(kind)/$(unit).dep)

  $$(cmi) : my_unit ::= $$(unit)
  $$(cmi) : $$(src) $$(kind)/$$(unit).dep
	$$(due_to)
	$$(CXX) -x c++-$(kind)-header $$(my_unit) -c -fmodule-mapper=header-mapper.txt $$(CXXFLAGS) $$(CPPFLAGS) \
 $$(TARGET_ARCH)
	@echo
endef

# include information about source names
CXX_UNIT_SRC_MOD_CMI_KIND_LIST ::=
include $(infofiles_sys) $(infofiles_user)
# $(info CXX_UNIT_SRC_MOD_CMI_KIND_LIST = $(CXX_UNIT_SRC_MOD_CMI_KIND_LIST))

# evaluate information from infofiles and generate:
# rules for unit cmi files
# a cmi files list
cmifiles ::=
ifndef CXX_UNIT_SRC_MOD_CMI_KIND_LIST
  $(info No rules to generate.)
endif
$(foreach line,$(CXX_UNIT_SRC_MOD_CMI_KIND_LIST),\
  $(let unit src mod cmi kind,$(subst ;, ,$(line)),\
      $(eval cmifiles += $(cmi))\
      $(eval $(cmi_file_rule))\
  )\
)
$(info )
$(info cmifiles = '$(cmifiles)')
$(info )

# include the depfile rules
include $(depfiles_sys) $(depfiles_user)

# make a final list of cmi file names
header-cmis.txt : $(cmifiles)
	$(due_to)
	@for x in $^; do echo "$$x"; done > $@
	@echo -e 'Header Units translation complete.\n'

# cleanup
.PHONY : clean
clean :
	$(due_to)
	LIST=; for x in $(CXX_MODULE_CACHE)/*; do if [[ -d $${x} ]]; then LIST+=" $${x}"; fi; done; rm -rfv $${LIST};
	rm -f header-cmis.txt
	rm -rf $(dirs_infofiles_sys)
	rm -rf $(dirs_infofiles_user)
	rm -f header-mapper.txt
	@echo

.PHONY : purge
purge : clean
	$(due_to)
	rm -f header-units-config header-units-config.temp
	rm -f header-units-list header-units-list.temp
	rm -rf system user
	@echo

# Append the Order Only Prerequisites for the infofile directories:

# Get the directory part of the target but skip pure . pattern.
target_dir_but_not_dot_dir = $(filter-out .,$(@D))

.SECONDEXPANSION :

$(infofiles_sys) : | $$(target_dir_but_not_dot_dir)
$(infofiles_user) : | $$(target_dir_but_not_dot_dir)

$(info **** End reading makefile $(this_makefile))
$(info )
