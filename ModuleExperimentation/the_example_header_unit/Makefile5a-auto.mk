# The rules for the example with header units
# Module dependencies expressed in generated rules.
# With automatic dependency generation using the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST schema.
#
# Requires Makefile5a-auto-headers.mk and Makefile5a-auto-header-names.mk for header unit translation.
# Header translation is forced to complete before dependency scan.
# System header translation takes place before user header translation.
# Header information scan is forced to complete before header translation.
#
# The dependency scan generates the 'depfiles' with the usual rules for header dependencies and the module information
# as variable CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST.
# One 'depfile' substitutes all legacy header dependencies of an source file. Thus the target of the header dependency
# rule is the depfile.
# A re-build of a 'depfile' takes place only when the source or one of the included headers has changed.
#
# After completion of the dependency scan, make potentially re-starts the script and builds all object files, cmi files
# and finally the target program.

# Required: p1689_to_mk.sh

MAKEFLAGS += -r

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) $(this_makefile) with goals $(MAKECMDGOALS))

# default target
my_program :

# project definitions
include project.mk

# export variables required in header makefiles
export CXM_SYSTEM_HEADER_UNITS
export CXM_USER_HEADER_UNITS

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# trigger dependent targets
FORCE :: ;

# Productive and non-productive goals must not be used simultaneously.
is_cleanup_goal ::= $(filter clean purge clean-%-units,$(MAKECMDGOALS))

# make header unit cmi files - must run once for productive goals at start up
ifndef MAKE_RESTARTS
  run_header_translation ::= $(if $(is_cleanup_goal),,1)
endif

ifdef run_header_translation

  header-info-system ::
	$(due_to)
	$(MAKE) -f Makefile5a-auto-header-names.mk KIND=SYSTEM $@
	@echo

  header-info-user ::
	$(due_to)
	$(MAKE) -f Makefile5a-auto-header-names.mk KIND=USER $@
	@echo

  header-map-system : FORCE | header-info-system
	$(due_to)
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=SYSTEM $@
	@echo

  header-map-user : FORCE | header-info-user header-map-system
	$(due_to)
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=USER $@
	@echo

else

  header-map-user : ;
  header-map-system : ;
  header-info-user : ;
  header-info-system : ;

endif

# generate dependency files for source files
# header unit translation must be complete before dependency scan
# the depfile substitutes all header dependencies of the source
depfiles ::= $(SOURCES:.cpp=.dep)
$(depfiles) : %.dep: %.cpp | header-map-user
	$(due_to)
	g++ $< -MM -MF $@ -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
	./p1689_to_mk.sh $*.ddi $@ - $*.o $<
	@echo

.PHONY : depend
depend : $(depfiles)
	@echo 'Dependency information is up to date.'
	@echo

# include dep-files for dependency tree generation
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST ::=
# dep tree is not required for purge and clean* goals
ifndef is_cleanup_goal
  include $(depfiles)
endif

# mod2cmi - expand to the cmi-file-name for a given named module
# input: mod - the module name
mod2cmi = gcm.cache/$(mod).gcm

# reqs2cmi - expand to a list of cmi-files for named modules
#            header units are ignored
# input: reqs - the list of module/header names
reqs2cmi = $(foreach mod,$(reqs),$(if $(filter /% ./%,$(mod)),,$(mod2cmi)))

# macro for module rules
# input: src, obj, mod, reqs
# Grouped target rules must have a recipe.
define modul_rule_template
$(obj) $(mod2cmi) &: $(src) $(src:.cpp=.dep) $(reqs2cmi)
	$$(due_to)
	g++ -o $(obj) $(src) -c -std=c++20 -fmodules
	@echo
endef

# macro for no module translation units
# input: src, obj, reqs
# The recipe is added with a static pattern rule.
define no_modul_rule_fragment
$(obj) : $(src) $(src:.cpp=.dep) $(reqs2cmi)
endef

# generate rules for translation units and variables
modsources ::=
nomodsources ::=
nomodobjects ::=
cmifiles ::=
ifndef CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST
  $(info No rules to generate.)
endif
$(foreach line,$(CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST),\
	$(let unit obj src mod is_if reqs,$(subst ;, ,$(line)),\
		$(if $(subst -,,$(mod)),\
			$(info generate module rule $(obj) $(mod2cmi) &: $(src) $(src:.cpp=.dep) $(reqs2cmi))\
			$(eval $(modul_rule_template))\
			$(eval modsources += $(src))\
			$(eval cmifiles += $(mod2cmi))\
		,\
			$(info generate no module rule $(obj) : $(src) $(src:.cpp=.dep) $(reqs2cmi))\
			$(eval $(no_modul_rule_fragment))\
			$(eval nomodsources += $(src))\
			$(eval nomodobjects += $(obj))\
		)\
	)\
)

# recipe for non module sources
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	g++ -o $@ $< -c -std=c++20 -fmodules
	@echo

# link all together
objects ::= $(SOURCES:.cpp=.o)
my_program : $(objects)
	$(due_to)
	g++ -o my_program $(objects) -std=c++20 -fmodules
	@echo

# Pointless are things like:
#gcm.cache/,/%: FORCE
#	$(MAKE) -f Makefile5-auto-headers.mk KIND=USER $@

#gcm.cache/%: FORCE
#	$(MAKE) -f Makefile5-auto-headers.mk KIND=SYSTEM $@

# cleans all cmi files of named modules
depfiles_p1689 = $(SOURCES:.cpp=.ddi)
#deptempfiles ::= $(addsuffix ~,$(depfiles))
.PHONY : clean
clean :
	rm -f my_program
	rm -f $(objects)
	rm -fv gcm.cache/*.gcm
	rm -f $(depfiles)
	rm -f $(depfiles_p1689)
#	rm -f $(deptempfiles)
	@echo

# header unit cleanup
.PHONY : clean-header-units
clean-header-units : clean-user-header-units clean-system-header-units

.PHONY : clean-user-header-units
clean-user-header-units :
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=USER clean
	$(MAKE) -f Makefile5a-auto-header-names.mk KIND=USER clean
	@echo

.PHONY : clean-system-header-units
clean-system-header-units :
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=SYSTEM clean
	$(MAKE) -f Makefile5a-auto-header-names.mk KIND=SYSTEM clean
	@echo

# remove all generated artifacts
.PHONY : purge
purge : clean
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=USER purge
	$(MAKE) -f Makefile5a-auto-headers.mk KIND=SYSTEM purge
	$(MAKE) -f Makefile5a-auto-header-names.mk KIND=USER purge
	$(MAKE) -f Makefile5a-auto-header-names.mk KIND=SYSTEM purge
	rm -fv *.dep
	rm -fv *.dep~
	rm -fv *.ddi
	rm -fv *.o
	rm -rfv gcm.cache
	@echo

$(info **** End reading makefile $(this_makefile))
$(info )
