# The rules for the example with custom module mapping.
# Variables are used to express the module dependencies in prerequisites.
# With automatic dependency generation.
# Rules for module units are generated.
# The depfile substitutes all legacy header dependencies of an translation unit.

$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) in directory $(CURDIR))

sources = main.cpp src1.cpp src2.cpp
objects = $(sources:.cpp=.o)

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

# rule to generate dependency files and structured dependency files
depfiles ::= $(sources:.cpp=.dep)
p1689files ::= $(depfiles:.dep=.ddi)
%.dep %.ddi : %.cpp
	$(due_to)
	g++ $< -MM -MF '$*.dep' -MQ $*.dep -MQ $*.ddi -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c \
	-std=c++20 -fmodules
	./p1689_to_make.sh $*.ddi $*.o $*.dep # appends the module dependencies expressed by variables
	@echo

# module database / variables
module-variables.mk : $(p1689files)
	$(due_to)
	./p1689_to_make_db.sh $@ '.ddi' '.cpp' '.o' $^
	@echo

# include module database/variables
include module-variables.mk

# mod2cmi - expand to the cmi-file-name for a given named module
# input: mod - the module name
mod2cmi = modulecache/$(mod).gcm

# template rule for module sources
# input: mod, src
define modul_rule_template
$(src:.cpp=.o) $(mod2cmi) &: $(src:.cpp=.dep)
	$$(due_to)
	g++ -o $(src:.cpp=.o) $(src) -c -std=c++20 -fmodules -fmodule-mapper=module-map.txt
	@echo
endef

# newline variable
define nl


endef

# generate rules for module sources, module variables and module map
modsources ::=
modulemap ::=
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
	$(let src mod is_if,$(subst ;, ,$(line)),\
		$(info generate module rule $(src))\
		$(eval $(modul_rule_template))\
		$(eval CXX_MOD_$(mod)_CMI = $(mod2cmi))\
		$(eval modsources += $(src))\
		$(eval modulemap ::= $$(modulemap)$(mod) $(mod2cmi)$$(nl))\
	)\
)
$(info )

# figure out no module sources
nomodsources = $(filter-out $(modsources),$(sources))
nomodobjects = $(nomodsources:.cpp=.o)

# write module-map - avoid unnecessary updates
modulemap_old ::= $(file < module-map.txt)
ifneq ($(modulemap_old),$(modulemap))
  $(file > module-map.txt,$(modulemap))
endif

# include all depfiles
include $(depfiles)

# generate rules for no module sources
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	g++ -o $@ $< -c -std=c++20 -fmodules -fmodule-mapper=module-map.txt
	@echo

# finally link all together
my_program : $(objects)
	$(due_to)
	g++ -o my_program $(objects) -std=c++20 -fmodules
	@echo

.PHONY : clean
clean :
	rm -f my_program
	rm -f main.o src{1..2}.o
	rm -f main.dep src{1..2}.dep
	rm -f main.ddi src{1..2}.ddi
	rm -f module-variables.mk
	rm -f module-map.txt
	rm -rf modulecache
