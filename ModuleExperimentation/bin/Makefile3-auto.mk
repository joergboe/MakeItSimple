# Makefile for a project with C++ modules and automatic dependency scanning.
# Module dependencies expressed in generated rules.

# With automatic dependency generation based on structured dependency information.
# The CXX_SRC_OBJ_MOD_IF_REQ_LIST lists:
#    primary output; source; module-provided; is-interface[; mod-required[ ;mod-required..]]
# The depfile substitutes all legacy header dependencies of an translation unit.
# Grouped Target Rules for module units and non module units are generated with 'eval'.

# The automatic variable $? is fixed because the grouped rule peps are complete

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

# Function 'get_cmi_name' expands to the CMI file name for project modules.
# Input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  get_cmi_name = $(CXX_MODULE_CACHE)/$(subst :,-,$1).gcm
else
  get_cmi_name = $(CXX_MODULE_CACHE)/$(2:.cpp=).gcm
endif

# The default target must be the first target.
TARGET ?= main
$(TARGET) :

# The rule for the dependency scan generates depfiles.
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	$(CXX) '$<' -MM -MF '$@' -MQ '$@' -fdeps-format=p1689r5 -fdeps-file='$*.ddi' -fdeps-target='$*.o' -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(bin)p1689_to_make.sh -p '$*.ddi' '$*.dep' '$*.o' '$<'
	@echo

# Including the provided modules database: CXX_SRC_OBJ_MOD_IF_LIST and the dependency rules.
CXX_SRC_OBJ_MOD_IF_REQ_LIST ::= # prefer simple variable flavor for the list with provided modules
include $(depfiles)

# Generating variables CXX_MOD_$(modi)_CMI for all project modules an module map and check for duplicate module.
# Provided local variables:
#    src - source file name
#    mod - the module name
#    modi - internal module name (colon is replaced with dash)
#    cmi  - cmi name
modulemap ::= # ensure the simply expanded variable flavor for the output variables
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_REQ_LIST),\
  $(let src obj mod is_if reqs,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi,$(subst :,-,$(mod)) $(call get_cmi_name,$(mod),$(src)),\
        $(if $(CXX_MOD_$(modi)_CMI),\
          $(error Duplicate module $(mod) in source unit $(src))\
        )\
        $(info CXX_MOD_$(modi)_CMI ::= $(cmi))\
        $(eval CXX_MOD_$$(modi)_CMI ::= $$(cmi))\
        $(eval modulemap += $$(mod);$$(cmi))\
      )\
    )\
  )\
)

# TODO: Generate variables and modulemap for imported cmi files.
# TODO: Check missing module requirements.
# TODO: Check 'keep going' in duplicate modules check.

# Do we use a non default module mapping?
user_mapping = $(if $(subst gcm.cache,,$(CXX_MODULE_CACHE)),1,$(if $(CXX_SIMPLE_MAPPING),1))

# mapper option
mapper_opt = $(if $(user_mapping),-fmodule-mapper=module-map.modm)
# The content of the module map depends on the configuration of the build and does not change for one
# configuration. So the module map is not a dependency for object files and cmi files.

# Defining some variables to hide spacial chars.
define nl


endef
empty ::=
space ::= $(empty) $(empty)

# Writing the module-map.
# NOTE: Trailing spaces are significant in module map format.
modulemap_subst ::= $(subst ;, ,$(subst $(space),$(nl),$(modulemap)))
$(file > module-map.modm,$(modulemap_subst))

# Macro reqs2cmi expands to all required cmi file names.
# Requires the local variable reqs with the list of all required modules.
reqs2cmi = $(foreach m,$(reqs),$(CXX_MOD_$(subst :,-,$(m))_CMI))

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# Using the following local variables as input.
#    src - source file name
#    obj - object name
#    dep - depfile name
#    cmi - cmi file name
#    reqs - all required modules
ifeq ($(CXX_SIMPLE_MAPPING),)
  define modul_rule_template
  $(info generate module rule    $(obj) $(cmi) &: $(src) $(dep) $(reqs2cmi))

  $$(obj) $$(cmi) : my_obj ::= $$(obj)
  $$(obj) $$(cmi) &: $$(src) $$(dep) $$(reqs2cmi)
	$$(due_to)
	$$(CXX) -o '$$(my_obj)' '$$<' -c $$(mapper_opt) $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	@echo
  endef
else
  # For simple mapping, the rule is generated without recipe.
  define modul_rule_template
  $(info generate module rule $(obj) $(cmi) : $(src) $(dep) $(reqs2cmi))

  $$(obj) $$(cmi) : $$(src) $$(dep) $$(reqs2cmi)
  endef
endif

# The template rule fragment for non module sources without recipe.
# Using the following local variables as input.
# input: src, obj, dep, reqs
define no_modul_rule_fragment
$(info generate no module rule $(obj) : $(src) $(dep) $(reqs2cmi))
$$(obj) : my_map_option ::= $$(if $$(reqs),$$(mapper_opt))
$$(obj) : $$(src) $$(dep) $$(reqs2cmi)
endef

# Generating rules for module units and non module units.
# Provided local variables:
#        src - source file name
#        obj - object name
#        mod - the module name
#        is_if - is interface (0/1)
#        dep - defile name
#        modreq - the required cmi files list
#        cmi  - cmi name (for modules only)
modsources ::= # ensure the simply expanded variable flavor for the output variables
nomodsources ::=
nomodobjects ::=
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_REQ_LIST),\
  $(let src obj mod is_if reqs,$(subst ;, ,$(line)),\
    $(let dep,$(src:.cpp=.dep),\
      $(if $(subst -,,$(mod)),\
        $(let cmi,$(call get_cmi_name,$(mod),$(src)),\
          $(eval $(modul_rule_template))\
          $(eval modsources += $$(src))\
        )\
      ,\
        $(eval $(no_modul_rule_fragment))\
        $(eval nomodsources += $$(src))\
        $(eval nomodobjects += $$(obj))\
      )\
    )\
  )\
)
$(info modsources = $(modsources))
$(info nomodsources = $(nomodsources))
$(info )

# Completing the rules for non module units.
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	$(CXX) -o '$@' '$<' -c $(my_map_option) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo

# Generate 'Pattern Rules' for for module units if Simple Mapping is activated.
ifneq ($(CXX_SIMPLE_MAPPING),)
  %.o $(CXX_MODULE_CACHE)/%.gcm :: %.cpp %.dep
	$(due_to)
	$(CXX) -o '$(<:.cpp=.o)' '$<' -c $(mapper_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo
endif

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
	rm -fv *.dep
	rm -fv *.dep~
	rm -fv *.ddi
	rm -fv module-map.modm
	rm -rfv '$(CXX_MODULE_CACHE)'
