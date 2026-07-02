# The rules for the example.
# Module dependencies expressed in generated rules.
# With automatic dependency generation.
# Rules for module units and non module units are generated.
# The depfile substitutes all legacy header dependencies of an translation unit.

# The automatic variable $? is fixed because the grouped rule peps are complete
# The header dependencies are substituted with dep file.

$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) in directory $(CURDIR))

.SUFFIXES:

sources = main.cpp src1.cpp src2.cpp
objects = $(sources:.cpp=.o)

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

# rule to generate dependency files and structured dependency files
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
	./p1689_to_make_tab.sh $*.ddi $@ $< $*.o # append the module dependencies as table
	@echo

# include depfiles with header and module dependency
CXX_OBJ_SRC_MOD_IF_REQ_LIST ::=
include $(depfiles)

# mod2cmi - expand to the cmi-file-name for a given named module
# input: mod - the module name
mod2cmi = gcm.cache/$(mod).gcm

# reqs2cmi - expand all prerequisite modules to cmi files
# input: reqs - list of prerequisite modules
reqs2cmi = $(foreach mod,$(reqs),$(mod2cmi))

# template rule for module sources
# input: obj, mod, src, reqs
define modul_rule_template
$(obj) $(mod2cmi) &: $(src) $(src:.cpp=.dep) $(reqs2cmi)
	$$(due_to)
	g++ -o $(obj) $(src) -c -std=c++20 -fmodules
	@echo
endef

# template rule fragment for non module sources
# input: obj, mod, src, reqs
define no_modul_rule_fragment
$(obj) : $(src) $(src:.cpp=.dep) $(reqs2cmi)
endef

# generate rules for module units and non module units and variables
modsources ::=
nomodsources ::=
nomodobjects ::=
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
	$(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
		$(if $(subst -,,$(mod)),\
			$(info generate module rule $(obj) $(mod2cmi) &: $(src:.cpp=.dep) $(reqs2cmi))\
			$(eval $(modul_rule_template))\
			$(eval modsources += $(src))\
		,\
			$(info generate no module rule $(obj) : $(src:.cpp=.dep) $(reqs2cmi))\
			$(eval $(no_modul_rule_fragment))\
			$(eval nomodsources += $(src))\
			$(eval nomodobjects += $(obj))\
		)\
	)\
)
$(info )

# complete the rules for non module units
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	g++ -o $@ $< -c -std=c++20 -fmodules
	@echo

# Link all together
my_program : $(objects)
	$(due_to)
	g++ -o my_program $(objects) -std=c++20 -fmodules
	@echo

depfiles_p1689 ::= $(sources:.cpp=.ddi)
.PHONY : clean
clean :
	rm -f my_program $(objects)
	rm -f $(depfiles)
	rm -f $(depfiles_p1689)
	rm -rf gcm.cache
