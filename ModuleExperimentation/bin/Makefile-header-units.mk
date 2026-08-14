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
include project.mk

# required compiler options
CXXFLAGS ?= -std=c++20 -fmodules
CXXFLAGS += -flang-info-include-translate -flang-info-module-cmi

# Delete the stored Header Units list if the list has changed.
units ::= $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS)
ifndef MAKE_RESTARTS
  old_units ::= $(file < header-units-list)
  ifneq ($(units),$(old_units))
    $(info !Header Units list has changed!)
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
	echo '$(units)' > $@
	@echo

# Delete the stored configuration file if the configuration has changed.
ifndef MAKE_RESTARTS
  $(file > header-units-config.temp,$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)) # store configuration in make to avoid shell quoting issues
  $(info $(shell if diff header-units-config header-units-config.temp; then\
      echo "No changes in Header Units configuration.";\
    else\
      rm -f header-units-config; echo "!Header Units configuration has changed!";\
    fi))
    $(info )
endif

# A missing configuration file triggers this rule.
header-units-config :
	$(due_to)
	mv header-units-config.temp $@
	@echo

# The module cache directory must be different from the default gcm.cache.
CXX_MODULE_CACHE ?= cmi_cache

# Generate infofiles : The source file name is figured out from script dep_2src.sh and the cmi file name is constructed.
# Output : CXX_UNIT_SRC_MOD_CMI_KIND_LIST
# Source file may be relative or absolute.
infofiles_sys ::= $(addsuffix .dep.n,$(CXX_SYSTEM_HEADER_UNITS))
$(infofiles_sys) : %.dep.n: header-units-list header-units-config
	$(due_to)
	$(CXX) -x c++-system-header $* -c -MM -MF $*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}get_info.sh $*.dep.0 $@ $* $(CXX_MODULE_CACHE) gcm system # provide variable CXX_UNIT_SRC_CMI_LIST
	@echo

infofiles_user ::= $(addsuffix .dep.n,$(CXX_USER_HEADER_UNITS))
$(infofiles_user) : %.dep.n: header-units-list header-units-config
	$(due_to)
	$(CXX) -x c++-user-header $* -c -MM -MF $*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}get_info.sh $*.dep.0 $@ $* $(CXX_MODULE_CACHE) gcm user # provide variable CXX_UNIT_SRC_CMI_LIST
	@echo

# generate database cmi mapper - output <logical name> <cmi>
header-mapper.txt : $(infofiles_sys) $(infofiles_user)
	$(due_to)
	@cat $^ | { IFS=\;; while read -r -a ar; do echo "$${ar[2]//\$$\$$/\$$} $${ar[3]//\$$\$$/\$$}"; done; } > "$@"
	@echo

# generate the depfiles
depfiles_sys ::= $(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS))
$(depfiles_sys) : %.dep : header-mapper.txt
	$(due_to)
	$(CXX) -x c++-system-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$*.o \
 -fdeps-file=$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}add_module_dep.sh header-mapper.txt $(CURDIR) $@.1 $@
	@echo

depfiles_user ::= $(addsuffix .dep,$(CXX_USER_HEADER_UNITS))
$(depfiles_user) : %.dep : header-mapper.txt
	$(due_to)
	$(CXX) -x c++-user-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$*.o \
 -fdeps-file=$*.ddi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	${my_bin_dir}add_module_dep.sh header-mapper.txt $(CURDIR) $@.1 $@
	@echo

# rule template for unit cmi file targets
# automatic header inclusion is effective
define cmi_file_rule
  $(info generate $(unit) rule : $(cmi) : $(src) $(unit).dep)

  $$(cmi) : my_unit ::= $$(unit)
  $$(cmi) : $$(src) $$(unit).dep
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
	rm -f *.dep.n
	rm -f *.dep.0
	rm -f header-mapper.txt
	rm -f *.dep
	rm -f *.dep.1
	rm -f *.ddi
	@echo

.PHONY : purge
purge : clean
	$(due_to)
	rm -f header-units-config header-units-config.temp
	rm -f header-units-list
	@echo

$(info **** End reading makefile $(this_makefile))
$(info )
