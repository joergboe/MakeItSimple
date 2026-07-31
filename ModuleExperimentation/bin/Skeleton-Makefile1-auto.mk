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
# * The dependency file 1 (dbmfiles - %.depm) contains information about provided module of the translation unit and
#   is based on structured dependency information (%.ddi).
#   The CXX_SRC_MOD_IF_LIST list contains a triple <primary output; source; module-provided; is-interface> for
#   each translation unit.
#
# * The variables CXX_MOD_modulname_CMI are defined based on variable CXX_SRC_MOD_IF_LIST.
#
# * A file with the mapping of module name to CMI filename is generated and stored in file 'module-map.txt'
#
# * Translation units that export a module are managed using Grouped Target Rules or Pattern Rules, depending on
#   the module mapping. Grouped Target Rules are generated with make function 'eval'. If the CMI filename is derived
#   from the source name via simple pattern substitution, pattern rules can be applied directly.
#
# * The remaining translation units are managed with Pattern Rules.
#
# --------------------------------------------------------------------------

# rules to generate depfiles and dbmfiles
%.dep %.depm : %.cpp
	g++ -M -MF $*.dep ... -fdeps-format=p1689r5 ...
	p1689_to_make.sh ...
	..

# include the provided modules database: CXX_SRC_MOD_IF_LIST
include $(dbmfiles)

# Variable CMI_mapper expands to the CMI file name.
# input: 1 - module name
#        2 - source file name
cmi_mapper = modulecache/$(subst :,-,$1).gcm# default mapping
cmi_mapper = modulecache/$2.gcm# simple mapping

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# input: src - source file name
#        obj - object name
#        cmi - CMI file name
define
modul_rule_template =
$(obj) $(cmi) : my_obj ::= $(obj)
$(obj) $(cmi) &: $(src) module-map.txt
	g++ -o '$(my_obj)' '$<' -c -fmodule-mapper=module-map.txt ...
endef
modul_rule_template =# simple mapping

# provide required module variables CXX_MOD_module_required_CMI
# generate rules + recipes for translation units providing a module
# prepare module map
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
  $(let src mod is_if,$(subst ;, ,$(line)),\
  
    $(eval CXX_MOD_$$(modi)_CMI ::= $$(cmi))\)\
    $(eval modsources += $$(src))\
    $(eval $(modul_rule_template))\
    $(eval modulemap += $$(mod);$$(cmi))\
    ...
  )\
)

# write module map if necessary
ifne(...)
  $(file > module-map.txt,...)
endif

# include all depfiles after definition of all CXX_MOD_module_CMI variables
# depfiles also require cmi_mapper function
include $(depfiles)

# rules for no module sources and simple module mapping
$(nomodobjects) : %.o : %.cpp module-map.txt
	$(CXX) -o '$@' '$<' -c -fmodule-mapper=module-map.txt ...

# If simple module mapping is used the a Pattern Rule is used for translation units providing a module.
%.o modulecache/%.gcm :: %.cpp module-map.txt
	$(CXX) -o $(<:.cpp=.o) $< -c -fmodule-mapper=module-map.txt ...

# link all together
$(TARGET) : $(objects)
	$(CXX) -o $(TARGET) $^ ...

# --------------------------------------------------------------------------

# *** Structure of dependency file (%.dep) ***
# The dependency file contains the makfile rules for the translation unit.
# (1) The firs rule lists the non module prerequisites, source file, header includes.
# (2) The second rule lists the required module interfaces if any.

# Module Units
# (1)
src.o $(call cmi_mapper,module_provided,src.cpp) src.dep src.depm: src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
src1.o $(call cmi_mapper,module_provided,src.cpp) : $(CXX_MOD_module_required_CMI) ...

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

