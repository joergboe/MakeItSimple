# This makefile generates cmi files for header units with automatic dependency generation
# and uses the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST schema.

# With variable KIND=SYSTEM system header units are build and the names are expected in variable CXM_SYSTEM_HEADER_UNITS
# With variable KIND=USER user header units are build and the names are expected in variable CXM_USER_HEADER_UNITS

# Requires that the file header-info-$(kind) with header name and source info exists.
# Makes a separate dep scan -restart cycle.

# Required: p1689_to_mk_all_features.sh -d

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) $(this_makefile) with kind $(KIND) and goals $(MAKECMDGOALS))

# Default target must come first
header-map-$(kind) :

ifndef KIND
  KIND ::= SYSTEM
endif
ifeq ($(KIND),SYSTEM)
  kind ::= system
else ifeq ($(KIND),USER)
  kind ::=user
else
  $(error Invalid KIND)
endif

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# If the list of header unit is changed, clean all cmi-files to avoid out dated files in cmi-cache.
.SECONDARY : header-info-$(kind)-done
header-info-$(kind)-done : header-info-$(kind)
	$(due_to)
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=$(KIND) clean
	touch header-info-$(kind)-done
	@echo

# include header source file names - file must exist
CXX_UNIT_SRC_LIST ::=
ifeq ($(filter clean purge,$(MAKECMDGOALS)),)
  include header-info-$(kind)
endif

# rule for depfiles
define dep_file_rule
  $(info generate depfile rule: $(unit).dep : $(src) header-info-$(kind)-done)

  $(unit).dep : $(src) header-info-$(kind)-done
	$$(due_to)
	g++ -x c++-$(kind)-header $(unit) -c -std=c++20 -fmodules -MM -MF $(unit).dep -MQ $(unit).dep -MP -fdeps-format=p1689r5 -fdeps-target=$(unit).o -fdeps-file=$(unit).ddi
	./p1689_to_mk_all_features.sh -d $(unit).ddi $(unit).dep $(unit) $(unit).o $(src)
	@echo
endef

# generate depfile rules
ifndef CXX_UNIT_SRC_LIST
  $(info No depfile rule to generate)
endif
$(foreach line,$(CXX_UNIT_SRC_LIST),\
	$(let unit src,$(subst ;, ,$(line)),\
		$(eval $(dep_file_rule))\
	)\
)

# files with module information
depfiles ::= $(addsuffix .dep,$(CXX_$(KIND)_HEADER_UNITS))

# depfiles include - rules to build theses files exist
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST ::=
ifeq ($(filter clean purge,$(MAKECMDGOALS)),)
  include $(depfiles)
endif

comma ::= ,
empty ::=
space ::= $(empty) $(empty)

# repl - replace: '.' by ',' and '..' by ',,'
# input: dir - path component
repl = $(if $(subst ..,,$(dir)),$(if $(subst .,,$(dir)),$(dir),$(comma)),$(comma)$(comma))

# rheader2cmi - converts a relative header name to the file name in gcm cache according to the gcc rules
# input: mod - the header name starting with ./
rheader2cmi = gcm.cache/$(subst $(space),/,$(foreach dir,$(subst /, ,$(mod)),$(repl))).gcm

# mod2cmi - expands to the cmi-file-name for a given module-name
# input: mod - the module/header name
mod2cmi = $(if $(patsubst /%,,$(mod)),$(if $(patsubst ./%,,),gcm.cache/$(mod).gcm,$(rheader2cmi)),gcm.cache$(mod).gcm)

# reqs2cmi - expand to a list of cmi-files for named modules
# input: reqs - the list of module/header names
reqs2cmi = $(foreach mod,$(reqs),$(mod2cmi))

# rule template for unit cmi file targets
# automatic header inclusion is effective
define cmi_file_rule
  $(info generate $(unit) rule : $(mod2cmi) : $(src) $(unit).dep $(reqs2cmi))

  $(mod2cmi) : $(src) $(unit).dep $(reqs2cmi)
	$$(due_to)
	g++ -x c++-$(kind)-header $(unit) -c -std=c++20 -fmodules
	touch $$@
	@echo
endef

# evaluate information from depfiles and generate:
# rules for unit cmi files
# a cmi files list
# the global header map
cmifiles ::=
header_map ::=
ifndef CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST
  $(info No rules to generate.)
endif
$(foreach line,$(CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST),\
	$(let unit obj src mod is_if reqs,$(subst ;, ,$(line)),\
		$(if $(subst -,,$(mod)),\
			$(eval cmifiles += $(mod2cmi))\
			$(eval header_map ::= $$(header_map)$$(mod) $$(mod2cmi)\n)\
			$(eval $(cmi_file_rule))\
		,\
			$(warning $(kind) interface unit with no logical name in unit $(unit) !)\
		)\
	)\
)

$(info cmifiles = '$(cmifiles)')

# generate system header map
header-map-$(kind) : $(cmifiles)
	$(due_to)
	@echo -en '$(header_map)' > $@
	@echo -e '$(KIND) units complete.\n'

# Cleanup
p1689files ::= $(addsuffix .ddi,$(CXX_$(KIND)_HEADER_UNITS))
tempfiles ::= $(addsuffix ~,$(depfiles))
.PHONY : clean
clean :
	rm -f header-map-$(kind)
ifeq ($(KIND),SYSTEM)
	LIST=(); for x in gcm.cache/*; do if [[ -d $${x} && $${x} != 'gcm.cache/,' ]]; then LIST+=("$${x}"); fi; done; rm -rfv "$${LIST[@]}";
else
	rm -rfv 'gcm.cache/,'
endif
	rm -f $(depfiles)
	rm -f $(tempfiles)
	rm -f $(p1689files)
	@echo

.PHONY : purge
purge : clean
	rm -f header-info-$(kind)-done
	@echo

$(info **** End reading makefile $(this_makefile))
$(info )
