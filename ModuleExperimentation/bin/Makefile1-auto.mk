# Makefile for a project with C++ modules and automatic dependency scanning.

# The automatic variable $? is fixed because the grouped rule prerequisites are complete.

# The makefile implements 2 custom module mappings:
#    If CXX_SIMPLE_MAPPING is undefined the name of the cmi file is         modulecache/<modulname>.gcm
#    If CXX_SIMPLE_MAPPING has a nonempty value the name of the cmi file is modulecache/<sourcefile>.gcm

# With CXX_SIMPLE_MAPPING=1:
# Problem with grouped pattern rule dependency propagation. (delete src1.o src2.o)

$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) in directory $(CURDIR))

SHELL = /bin/bash
.SHELLFLAGS ::= -ec

# Getting path of this makefile.
bin ::= $(dir $(lastword $(MAKEFILE_LIST)))

# Collecting all source files in current directory.
sources ::= $(wildcard *.cpp)
$(info sources = $(sources))

# Module Cache Directory
CXX_MODULE_CACHE ?= gcm.cache

# Defining required compiler options.
CXXFLAGS ?= -std=c++20 -fmodules

# Macros to display information about the running recipe.
due_to = @echo 'Run target $@ - Due to $?'

# Module to CMI file mapper function - expands to the cmi file name or nothing.
# Input: 1 - Module Name
mmap = $(CXX_MODULE_CACHE)/$(subst :,-,$1).gcm

# Function 'get_cmi_name' expands to the CMI file name for project modules.
# Input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  get_cmi_name = $(call mmap,$1)
else
  get_cmi_name = $(CXX_MODULE_CACHE)/$(2:.cpp=).gcm
endif

# The default target must be the first target.
TARGET ?= main
$(TARGET) :

# The rule for the dependency scan generates depfiles and dbmfiles.
%.d.dep %.m.dep : %.cpp
	$(due_to)
	$(CXX) '$<' -MM -MF '$*.d.dep' -MQ '$*.o' -MQ '$*.d.dep' -MQ '$*.m.dep' -fdeps-format=p1689r5 -fdeps-file='$*.ddi' -fdeps-target='$*.o' -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
ifeq ($(CXX_SIMPLE_MAPPING),)
	$(bin)p1689_to_make.sh -f -s -u -m '$*.m.dep' '$*.ddi' '$*.d.dep' '$*.o' '$<'
else
	$(bin)p1689_to_make.sh -f -s -m '$*.m.dep' -c '$(CXX_MODULE_CACHE)/$(<:.cpp=).gcm' '$*.ddi' '$*.d.dep' '$*.o' '$<'
endif
	@echo

# Including the provided modules database: CXX_SRC_OBJ_MOD_IF_LIST
dbmfiles ::= $(sources:.cpp=.m.dep)
CXX_SRC_OBJ_MOD_IF_LIST ::= # Prefer simple variable flavor for the list with provided modules.
include $(dbmfiles)

# Do we use a non default module mapping?
user_mapping = $(if $(subst gcm.cache,,$(CXX_MODULE_CACHE)),1,$(if $(CXX_SIMPLE_MAPPING),1))

# mapper option
mapper_opt = $(if $(user_mapping),-fmodule-mapper=module-map.modm)
# The content of the module map depends on the configuration of the build and does not change for one
# configuration. So the module map is not a dependency for object files and cmi files.

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# Using the following local variables as input.
#    src - source file name
#    obj - object name
#    cmi - cmi file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  define modul_rule_template
  $(info generate module rule $(obj) $(cmi) &: $(src))

  $$(obj) $$(cmi) : my_obj ::= $$(obj)
  $$(obj) $$(cmi) &: $$(src)
	$$(due_to)
	$$(CXX) -o '$$(my_obj)' '$$<' -c $$(mapper_opt) $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	@echo
  endef
else
  modul_rule_template = # Rules for module units are provided as 'Pattern Rule'.
endif

# TODO: Generate variables and modulemap for imported cmi files.
# TODO: Check missing module requirements.

# Generating rules for module sources, module variables and module map and check for duplicate module.
# Provided local variables:
#    src - source file name
#    obj - object name
#    mod - the module name
#    is_if - is interface (0/1)
#    modi - internal module name (colon is replaced with dash)
#    cmi  - cmi name
modsources ::= # Ensure the simply expanded variable flavor for the output variables.
nomodsources ::=
modulemap ::=
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_LIST),\
  $(let src obj mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi,$(subst :,-,$(mod)) $(call get_cmi_name,$(mod),$(src)),\
        $(if $(CXX_MOD_$(modi)_CMI),\
          $(error Duplicate module $(mod) in source unit $(src))\
        )\
        $(info CXX_MOD_$(modi)_CMI ::= $(cmi))\
        $(eval CXX_MOD_$$(modi)_CMI ::= $$(cmi))\
        $(eval modsources += $$(src))\
        $(eval modulemap += $$(mod);$$(cmi))\
        $(eval $(modul_rule_template))\
      )\
    ,\
      $(eval nomodsources += $$(src))\
    )\
  )\
)
# TODO: Check 'keep going' in duplicate modules check.
$(info nomodsources = $(nomodsources))
$(info )

# Defining some variables to hide spacial chars.
define nl


endef
empty ::=
space ::= $(empty) $(empty)

# Writing the module-map.
# NOTE: Trailing spaces are significant in module map format.
modulemap_subst ::= $(subst ;, ,$(subst $(space),$(nl),$(modulemap)))
$(file > module-map.modm,$(modulemap_subst))

# Including all depfiles after definition of all CXX_MOD_module_CMI variables.
# The depfiles require the 'get_cmi_name' function also.
depfiles ::= $(sources:.cpp=.d.dep)
include $(depfiles)

# Generating 'Static Pattern Rules' for non module units.
nomodobjects ::= $(nomodsources:.cpp=.o)
$(nomodobjects) : %.o : %.cpp
	$(due_to)
	$(CXX) -o '$@' '$<' -c $(mapper_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo

# Generate 'Pattern Rules' for for module units if Simple Mapping is activated.
ifneq ($(CXX_SIMPLE_MAPPING),)
  %.o $(CXX_MODULE_CACHE)/%.gcm :: %.cpp
	$(due_to)
	$(CXX) -o '$(<:.cpp=.o)' '$<' -c $(mapper_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo
endif
# TODO: Is double colon rule appropriate?

# Finally link all together.
objects ::= $(sources:.cpp=.o)
$(TARGET) : $(objects)
	$(due_to)
	$(CXX) -o '$(TARGET)' $(foreach o,$(objects),'$(o)') $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)
	@echo

# Cleanup rule:
.PHONY : clean
clean :
	rm -fv '$(TARGET)'
	rm -fv *.o
	rm -fv *.d.dep
	rm -fv *.d.dep~
	rm -fv *.m.dep
	rm -fv *.ddi
	rm -fv module-map.modm
	rm -rfv '$(CXX_MODULE_CACHE)'
