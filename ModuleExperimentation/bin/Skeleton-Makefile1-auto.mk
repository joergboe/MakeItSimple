# Skeleton Makefile1-auto.mk

# * The automatic dependency detection is based on generated files. These files are generate running
#   the first 'Dependency Scan Rule'.
#
# * The dependency scan produces two dependency files for each translation unit: the depfile and the dbmfile.
#
# * The depfile (%.d.dep) contains the makefile rules without recipes as usual.
#
# * The dbmfile (%.m.dep) contains information about provided module of the translation unit in
#   CSV style and is based on structured dependency information (%.ddi).
#   The CXX_SRC_OBJ_MOD_IF_LIST list contains a quadruple <source;object;module-provided;is-interface> for
#   each translation unit.
#
# * A dependency scan for a specific source file is performed only if the dependency or database files are
#   missing or outdated.
#
# * If one of the dependency or database files is updated, Make is restarted and the dependency tree is rebuilt using
#   current data.
#
# * Variables are used to express module dependencies within the prerequisites. A variable such as
#   CXX_MOD_modulename_CMI establishes the link between the module name and the CMI filename.
#   These database variables are defined before the dependency rules are included.
#
# * The variables CXX_MOD_modulname_CMI are defined based on variable CXX_SRC_OBJ_MOD_IF_LIST.
#
# * A file with the mapping of module name to CMI filename is generated and stored in file 'module-map.modm'
#
# * Translation units that provide a module are managed — depending on the module mapping —
#   using either 'Grouped Target Rules' or 'Pattern Rules'.

# * If standard module mapping is used 'Grouped Target Rules' for module units are generated using make function 'eval'.
#
# * If the CMI filename is derived from the source name via simple pattern substitution (Simple Mapping), pattern rules
#   can be applied directly.
#
# * The remaining non-module translation units are managed with 'Static Pattern Rules'.
#
# * The mapping of module-name/source-name to CMI filename is provided from the make function 'get_cmi_name'.
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

# The rule for the dependency scan generates depfiles and dbmfiles.
%.d.dep %.m.dep : %.cpp
	g++ $< -MM -MF $*.d.dep -MQ $*.o -MQ $*.d.dep -MQ $*.m.dep -fdeps-format=p1689r5 -fdeps-file=$*.ddi -c ...
	p1689_to_make.sh ...
	...

# Including the provided modules database: CXX_SRC_OBJ_MOD_IF_LIST
dbmfiles ::= $(sources:.cpp=.m.dep)
include $(dbmfiles)

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# Using the following local variables as input.
#    src - source file name
#    obj - object name
#    cmi - cmi file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  define modul_rule_template
  $(obj) $(cmi) &: $(src)
	g++ -o $(obj) $< -c -fmodule-mapper=module-map.modm ...
  endef
else
  modul_rule_template = # Rules for module units are provided as 'Pattern Rule'.
endif

# Generating rules for module sources, module variables and module map and check for duplicate module.
# Provided local variables:
#        src - source file name
#        obj - object name
#        mod - the module name
#        is_if - is interface (0/1)
#        modi - internal module name (colon is replaced with dash)
#        cmi  - cmi name
$(foreach line,$(CXX_SRC_OBJ_MOD_IF_LIST),\
  $(let src obj mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi,$(subst :,-,$(mod)) $(call get_cmi_name,$(mod),$(src)),\
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

# Including all depfiles after definition of all CXX_MOD_module_CMI variables.
# The depfiles require the 'mmap' function also.
depfiles ::= $(sources:.cpp=.d.dep)
include $(depfiles)

# Generating 'Static Pattern Rules' for non module units.
nomodobjects = $(nomodsources:.cpp=.o)
$(nomodobjects) : %.o : %.cpp
	g++ -o $@ $< -c -fmodule-mapper=module-map.modm ...

# Generate 'Pattern Rules' for for module units if Simple Mapping is activated.
ifneq ($(CXX_SIMPLE_MAPPING),)
%.o modulecache/%.gcm :: %.cpp
	g++ -o $(<:.cpp=.o) $< -c -fmodule-mapper=module-map.modm ...
endif

# Finally link all together.
$(TARGET) : $(objects)
	g++ -o $(TARGET) $^ ...

# --------------------------------------------------------------------------

# *** Structure of dependency file (%.d.dep) ***
# The dependency file contains the makfile rules for the translation unit.
# (1) The first rule lists the non module prerequisites, source file, header includes.
# (2) The second rule lists the required module interfaces if any.

# Module Units:
# (1)
$(call mmap,module_provided) src.o src.d.dep src.m.dep: src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
$(call mmap,module_provided) src.o : $(CXX_MOD_module_required_CMI) ...

# Non Module Units:
# (1)
src.o src.d.dep src.m.dep: src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
src.o : $(CXX_MOD_module_required_CMI) ...

# *** Structure of module database file (%.m.dep) ***
# The module database file contains the information about provided module in form of a make variable.
# The CXX_SRC_OBJ_MOD_IF_LIST lists:
#    source;object;module-provided;is-interface

# Module Units:
CXX_SRC_OBJ_MOD_IF_LIST += src.cpp;src.o;module;1

# Non Module Units:
CXX_SRC_OBJ_MOD_IF_LIST += src.cpp;src.o;-;0
