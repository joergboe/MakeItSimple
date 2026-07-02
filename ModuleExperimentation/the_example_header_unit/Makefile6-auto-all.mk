# Part of Makefile6-auto.mk
# Make my_program, all objects and all depfiles
# Module dependencies expressed in generated rules.
# With automatic dependency generation using the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST schema.

# Required: p1689_to_mk.sh

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) $(this_makefile) with goals $(MAKECMDGOALS))

# default target
my_program :

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# generate dependency files for source files
# header unit translation must be complete before dependency scan
# the depfile substitutes all header dependencies of the source
depfiles ::= $(SOURCES:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	g++ $< -MM -MF $@ -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
	./p1689_to_mk.sh $*.ddi $@ - $*.o $<
	@echo

# include dep-files for dependency tree generation
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST ::=
include $(depfiles)

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

$(info **** End reading makefile $(this_makefile))
$(info )
