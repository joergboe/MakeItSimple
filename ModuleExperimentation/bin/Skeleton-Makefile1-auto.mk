# Skeleton Makefile1-auto.mk

# * Variables are used to express the module dependencies in prerequisites. A variable like CXX_MOD_modulname_CMI
#   substitutes the CMI file name by the module name. These database variables are defined in front of the dependency
#   rules.
#
# * The dependency scan is performed only if the dependency or database files are missing or outdated.
#
# * The dependency scan produces two dependency files for each translation unit: %.dep and %.depm.
#
# * The dependency file 1 (depfiles - %.dep) contains the makefile rules without recipes as usual.
#
# * The dependency file 2 (dbmfiles - %.depm) contains information about provided module of the translation unit in
#   CSV style and is based on structured dependency information (%.ddi).
#   The CXX_SRC_MOD_IF_LIST list contains a triple <primary output; source; module-provided; is-interface> for
#   each translation unit.
#
# * If one of the dependency or database files is updated, Make is restarted and the dependency tree is rebuilt using
#   current data.
#
# * The variables CXX_MOD_modulname_CMI are defined based on variable CXX_SRC_MOD_IF_LIST.
#
# * A file with the mapping of module name to CMI filename is generated and stored in file 'module-map.txt'
#
# * Translation units that export a module are managed using Grouped Target Rules or Pattern Rules, depending on
#   the module mapping. Grouped Target Rules are generated using make function 'eval'.
#
# * If the CMI filename is derived from the source name via simple pattern substitution (simple mapping), pattern rules
#   can be applied directly.
#
# * The remaining translation units are managed with Pattern Rules.
#
# --------------------------------------------------------------------------

# rules to generate depfiles and dbmfiles
%.dep %.depm : %.cpp
	g++ $< -M -MF $*.dep -MQ $*.dep -MQ $*.depm -MQ $*.o -MQ '$(call cmi_mapper,$(mod),$(src))' \
 -fdeps-format=p1689r5 -fdeps-file=$*.ddi ...
	p1689_to_make.sh ...
	..

# Variable CMI_mapper expands to the CMI file name.
# input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  cmi_mapper = modulecache/$(subst :,-,$1).gcm
else
  cmi_mapper = modulecache/$2.gcm
endif

# include the provided modules database: CXX_SRC_MOD_IF_LIST
dbmfiles ::= $(sources:.cpp=.depm)
include $(dbmfiles)

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# input: src - source file name
#        obj - object name
#        cmi - cmi file
ifeq ($(CXX_SIMPLE_MAPPING),)
define
modul_rule_template =
$(obj) $(cmi) &: $(src) module-map.txt
	g++ -o $(obj) $< -c -fmodule-mapper=module-map.txt ...
endef
else
modul_rule_template = # rule is provided as Pattern Rule
endif

# provide required module variables CXX_MOD_module_required_CMI
# generate rules + recipes for translation units providing a module
# provide module map, modsources and nomodsources
# let provides the local variables: src, mod, is_if, obj, modi and cmi
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let obj modi cmi,$(src:.cpp=.o) $(subst :,-,$(mod)) $(call cmi_mapper,$(mod),$(src)),\
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

# write module map if necessary
...
ifne(...)
  $(file > module-map.txt,...)
endif

# include all depfiles after definition of all CXX_MOD_module_CMI variables
# depfiles also require cmi_mapper function
depfiles ::= $(sources:.cpp=.dep)
include $(depfiles)

# rules for no module sources and simple module mapping
nomodobjects = $(nomodsources:.cpp=.o)
$(nomodobjects) : %.o : %.cpp %.dep module-map.txt
	g++ -o $@ $< -c -fmodule-mapper=module-map.txt ...

# If simple module mapping is used the a Pattern Rule is used for translation units providing a module.
ifneq ($(CXX_SIMPLE_MAPPING),)
%.o modulecache/%.gcm :: %.cpp %.dep module-map.txt
	g++ -o $(<:.cpp=.o) $< -c -fmodule-mapper=module-map.txt ...
endif

# link all together
$(TARGET) : $(objects)
	g++ -o $(TARGET) $^ ...

# --------------------------------------------------------------------------

# *** Structure of dependency file (%.dep) ***
# The dependency file contains the makfile rules for the translation unit.
# (1) The firs rule lists the non module prerequisites, source file, header includes.
# (2) The second rule lists the required module interfaces if any.

# Module Units
# (1)
$(call cmi_mapper,module_provided,src.cpp) src.o src.dep src.depm: src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
src.o $(call cmi_mapper,module_provided,src.cpp) : $(CXX_MOD_module_required_CMI) ...

# Non Module Units
# (1)
src.o src.dep src.depm: src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
src1.o : $(CXX_MOD_module_required_CMI) ...

# *** Structure of module database file (%.depm) ***
# contains the information about provided module in form of a variable
# The CXX_SRC_MOD_IF_LIST lists:
#    primary output; source; module-provided; is-interface

# Module Units
CXX_SRC_MOD_IF_LIST += src.cpp;module;1

# Non Module Units
CXX_SRC_MOD_IF_LIST += src.cpp;-;0

