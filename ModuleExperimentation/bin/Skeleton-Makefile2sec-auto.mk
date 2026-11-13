# Skeleton Makefile2sec-auto.mk

# Difference to Skeleton Makefile2-auto.mk:
# * Makefile2sec-auto.mk reduces the number of rules required once more.
#   Rules and information about provided module are written into a single dependency file.
#   Make uses the Second Expansion to get the current cmi file dependencies.
#
# --------------------------------------------------------------------------

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

# The rule for the dependency scan generates depfiles.
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) %.dep : %.cpp
	g++ $< -M -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi ...
	p1689_to_make_sec.sh ...
	...

.SECONDEXPANSION :

# Including the provided modules database: CXX_SRC_OBJ_MOD_IF_LIST
# CXX_MOD_require1_CMI variables are resolved during secondary expansion
depfiles ::= $(sources:.cpp=.dep)
include $(depfiles)

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# Using the following local variables as input.
#    src - source file name
#    obj - object name
#    dep - depfile name
#    cmi - cmi file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  define modul_rule_template
  $(obj) $(cmi) &: $(src) $(dep)
	g++ -o $(obj) $< -c -fmodule-mapper=module-map.modm ...
  endef
else
  modul_rule_template = # Rules for module units are provided as 'Pattern Rule'.
endif

# Generating rules for module sources, module variables and module map and check for duplicate module.
# Provided local variables:
#    src - source file name
#    mod - the module name
#    is_if - is interface (0/1)
#    modi - internal module name (colon is replaced with dash)
#    cmi  - cmi name
#    obj - object name
#    dep - depfile name
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_LIST),\
  $(let src obj mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let dep modi cmi,$(src:.cpp=.dep) $(subst :,-,$(mod)) $(call get_cmi_name,$(mod),$(src)),\
        $(eval CXX_MOD_$(modi)_CMI ::= $(cmi))\
        $(eval modsources += $(src))\
        $(eval $(modul_rule_template))\
        $(eval modulemap += $(mod);$(cmi))\
      )\
    ,\
      $(eval nomodsources += $(src))\
    )\
  )\
)

# Writing the module-map.
$(file > module-map.modm,...)

# Generating 'Static Pattern Rules' for non module units.
nomodobjects = $(nomodsources:.cpp=.o)
$(nomodobjects) : %.o : %.cpp %.dep
	g++ -o $@ $< -c -fmodule-mapper=module-map.modm ...

# Generate 'Pattern Rules' for for module units if Simple Mapping is activated.
ifneq ($(CXX_SIMPLE_MAPPING),)
%.o modulecache/%.gcm :: %.cpp %.dep
	g++ -o $(<:.cpp=.o) $< -c -fmodule-mapper=module-map.modm ...
endif

# Finally link all together.
$(TARGET) : $(objects)
	g++ -o $(TARGET) $^ ...

# --------------------------------------------------------------------------

# *** Structure of dependency file (%.dep) ***
# The dependency file contains the makefile rules for the translation unit and contains the information about provide
# module in form of a variable. The CXX_SRC_MOD_IF_LIST lists:
#    primary output; source; module-provided; is-interface

# (1) The firs rule lists the non module prerequisites for the depfiles.
# (2) The second rule lists the required module interfaces if any.
# (3) A variable contains the information about provided module.

# Module Units
# (1)
src.dep : src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
$(call mmap,module_provided) src.o : $(CXX_MOD_module_required_CMI) ...
# (3)
CXX_SRC_OBJ_MOD_IF_LIST += src.cpp;src.o;module;1

# Non Module Units
# (1)
src.dep : src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
src.o : $(CXX_MOD_module_required_CMI) ...
# (3)
CXX_SRC_OBJ_MOD_IF_LIST += src.cpp;src.o;-;0
