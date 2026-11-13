# Skeleton Makefile3-auto.mk

# With automatic dependency generation based on structured dependency information.
# The CXX_SRC_OBJ_MOD_IF_REQ_LIST lists:
#    primary output; source; module-provided; is-interface[; mod-required[ ;mod-required..]]
# The depfile substitutes all legacy header dependencies of an translation unit.
# Grouped Target Rules for module units and non module units are generated with 'eval'.

# --------------------------------------------------------------------------

# Function 'get_cmi_name' expands to the CMI file name for project modules.
# Input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  get_cmi_name = $(CXX_MODULE_CACHE)/$(subst :,-,$1).gcm
else
  get_cmi_name = $(CXX_MODULE_CACHE)/$(2:.cpp=).gcm
endif

# The rule for the dependency scan generates depfiles.
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi ...
	p1689_to_make.sh ... # append the module dependencies as CSV record
	...

# Including the provided modules database: CXX_SRC_OBJ_MOD_IF_LIST and the dependency rules.
include $(depfiles)

# Generating variables CXX_MOD_$(modi)_CMI for all project modules an module map and check for duplicate module.
# Provided local variables:
#    src - source file name
#    mod - the module name
#    modi - internal module name (colon is replaced with dash)
#    cmi  - cmi name
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_REQ_LIST),\
  $(let src obj mod is_if reqs,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi,$(subst :,-,$(mod)) $(call get_cmi_name,$(mod),$(src)),\
        $(eval CXX_MOD_$(modi)_CMI ::= $(cmi))\
        $(eval modulemap += $(mod);$(cmi))\
      )\
    )\
  )\
)

# Writing the module-map.
$(file > module-map.modm,...)

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
  $(obj) $(cmi) &: $(src) $(dep) $(reqs2cmi)
	g++ -o $(obj) $$< -c -fmodule-mapper=module-map.modm ...
  endef
else
  # For simple mapping, the rule is generated without recipe.
  define modul_rule_template
  $(obj) $(cmi) : $(src) $(dep) $(reqs2cmi)
  endef
endif

# The template rule fragment for non module sources without recipe.
# Using the following local variables as input.
# input: src, obj, dep, reqs
define no_modul_rule_fragment
$(obj) : $(src) $(dep) $(reqs2cmi)
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
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_REQ_LIST),\
  $(let src obj mod is_if reqs,$(subst ;, ,$(line)),\
    $(let dep,$(src:.cpp=.dep),\
      $(if $(subst -,,$(mod)),\
        $(let cmi,$(call get_cmi_name,$(mod),$(src)),\
          $(eval $(modul_rule_template))\
          $(eval modsources += $(src))\
        )\
      ,\
        $(eval $(no_modul_rule_fragment))\
        $(eval nomodsources += $(src))\
      )\
    )\
  )\
)

# Completing the rules for non module units.
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
# The dependency file contains the makfile rules for the translation unit and contains the information about provide
# module in form of a variable with a CSV record. The CXX_OBJ_SRC_MOD_IF_REQ_LIST lists:
#    primary output; source; module-provided; is-interface[; module-required[...]]

# (1) The firs rule lists the non module prerequisites for the depfiles.
# (2) A variable contains the information about provided module.

# Module Units:
# (1)
src.dep : src.cpp header.h ...
# (2)
CXX_SRC_OBJ_MOD_IF_REQ_LIST += src.cpp;src.o;module-provided;1;module-required[; ...]

# Non Module Units:
# (1)
src.dep : src.cpp header.h ...
# (3)
CXX_SRC_OBJ_MOD_IF_REQ_LIST += src.cpp;src.o;-;0;module-required[; ...]
