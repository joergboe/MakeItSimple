# The rules for the example.
# Module dependencies expressed in generated rules.
# With automatic dependency generation.
# With special module - cmi file name mapping: gcm.cache/src-name.cmi
# All module dependencies are generated.
# Rules for module units expressed as pattern rule with grouped targets.

# The automatic variable $? is fixed because the grouped rule peps are complete
# The header dependencies are substituted with dep file.

# Disadvantage: Module partitions generate cmi-files with colon which are not properly escaped in gcc and are forbidden
# in windows.

# Problem with grouped pattern rule dependency propagation. (delete src1.o)

$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) in directory $(CURDIR))

.SUFFIXES:

sources = main.cpp src1.cpp src2.cpp
objects = $(sources:.cpp=.o)

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

# rule to generate dependency files and structured dependency files
depfiles = $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
	./p1689_to_make_tab.sh $*.ddi $@ $< $*.o
	@echo

# include dependencies with header and module dependency
CXX_OBJ_SRC_MOD_IF_REQ_LIST ::=
include $(depfiles)

# get_cmi - expand to the cmi-file-name for a given module unit
# input: src - the source file name
get_cmi = gcm.cache/$(src).gcm

# provide module cmi file mapping in variables CXX_MOD_<mod>_CMI
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
	$(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
		$(eval CXX_MOD_$(mod)_CMI ::= $$(get_cmi))\
	)\
)

# reqs2cmi - expand all prerequisite modules to cmi files
# input: reqs - list of prerequisite modules
#        CXX_MOD_<mod>_CMI - module cmi mapping
reqs2cmi = $(foreach mod,$(reqs),$(CXX_MOD_$(mod)_CMI))

# template rule fragment for module sources
# input: obj, src, reqs, CXX_MOD_<mod>_CMI
define modul_rule_fragment
$(obj) $(get_cmi) : $(src) $(src:.cpp=.dep) $(reqs2cmi)
endef

# template rule fragment for non module sources
# input: obj, src, reqs, CXX_MOD_<mod>_CMI
define no_modul_rule_fragment
$(obj) : $(src) $(src:.cpp=.dep) $(reqs2cmi)
endef

define nl ::=


endef

# generate rules and some variables:
modsources ::=
nomodsources ::=
nomodobjects ::=
modulemap ::=
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
	$(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
		$(if $(subst -,,$(mod)),\
			$(info generate module rule $(obj) $(get_cmi) : $(src:.cpp=.dep) $(reqs2cmi))\
			$(eval $(modul_rule_fragment))\
			$(eval modsources += $(src))\
			$(eval modulemap ::= $$(modulemap)$$(mod) $$(get_cmi)$$(nl))\
		,\
			$(info generate no module rule $(obj) : $(src:.cpp=.dep) $(reqs2cmi))\
			$(eval $(no_modul_rule_fragment))\
			$(eval nomodsources += $(src))\
			$(eval nomodobjects += $(obj))\
		)\
	)\
)
$(info )

# write module map
$(file > modulemap.txt,$(modulemap))

# recipe for module units
%.o gcm.cache/%.cpp.gcm &: %.cpp %.dep
	$(due_to)
	g++ -o $*.o $< -c -std=c++20 -fmodules -fmodule-mapper=modulemap.txt
	@echo

# recipe for other sources
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	g++ -o $@ $< -c -std=c++20 -fmodules -fmodule-mapper=modulemap.txt
	@echo

# link all together
my_program : $(objects)
	$(due_to)
	g++ -o my_program $(objects) -std=c++20 -fmodules
	@echo

depfiles_p1689 = $(sources:.cpp=.ddi)
.PHONY : clean
clean :
	rm -f my_program $(objects)
	rm -f $(depfiles)
	rm -f $(depfiles_p1689)
	rm -rf gcm.cache
	rm -f modulemap.txt
