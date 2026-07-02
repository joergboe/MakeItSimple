# The module dependencies expressed with variables using secondary expansion
# Variables are used to express the module dependencies in prerequisites.
# With automatic dependency generation.
# Rules for module units are generated.
# The depfile substitutes all legacy header dependencies of an translation unit.

# The automatic variable $? is fixed because the grouped rule prerequisites are complete.

$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) in directory $(CURDIR))

sources = main.cpp src1.cpp src2.cpp
objects = $(sources:.cpp=.o)

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

# rule to generate dependency files
depfiles = $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
	./p1689_to_make_sec.sh $*.ddi $< $*.o $@ # rewrite dependencies for secondary exp. and append module deps
	@echo

# Include all depfiles
.SECONDEXPANSION :
include $(depfiles)

# mod2cmi - expand to the cmi-file-name for a given named module
# input: mod - the module name
mod2cmi = gcm.cache/$(mod).gcm

# module sources
define modul_rule_template
$(src:.cpp=.o) $(mod2cmi) &: $(src:.cpp=.dep)
	$$(due_to)
	g++ -o $(src:.cpp=.o) $(src) -c -std=c++20 -fmodules
	@echo
endef

# generate rules for module sources and module variables
modsources ::=
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
	$(let src mod is_if,$(subst ;, ,$(line)),\
		$(info generate module rule $(src))\
		$(eval $(modul_rule_template))\
		$(eval CXX_MOD_$(mod)_CMI = gcm.cache/$(mod).gcm)\
		$(eval modsources += $(src))\
	)\
)
$(info )

# figure out no module sources
nomodsources = $(filter-out $(modsources),$(sources))
nomodobjects = $(nomodsources:.cpp=.o)

# generate rules for no module sources
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	g++ -o $@ $< -c -std=c++20 -fmodules
	@echo

# link all together
my_program: $(objects)
	$(due_to)
	g++ -o my_program $(objects) -std=c++20 -fmodules
	@echo

.PHONY : clean
clean :
	rm -f my_program
	rm -f main.o src{1..2}.o
	rm -f main.dep src{1..2}.dep
	rm -f main.ddi src{1..2}.ddi
	rm -rf gcm.cache
