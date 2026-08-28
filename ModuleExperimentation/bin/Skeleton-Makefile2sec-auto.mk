# Skeleton Makefile2sec-auto.mk

# Difference to Skeleton Makefile2-auto.mk:
# * Makefile2sec-auto.mk reduces the number of rules required once more.
#   Rules and information about provided module are written into a single dependency file.
#   Make uses the Second Expansion to get the current cmi file dependencies.
#
# --------------------------------------------------------------------------

# rules to generate depfiles and dbmfiles
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) %.dep : %.cpp
	g++ $< -M -MF $@ -MQ $@.dep -fdeps-format=p1689r5 -fdeps-file=$*.ddi ...
	p1689_to_make_sec.sh ... # merges all into one file
	..

# Variable CMI_mapper expands to the CMI file name.
# input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  cmi_mapper = modulecache/$(subst :,-,$1).gcm
else
  cmi_mapper = modulecache/$2.gcm
endif

.SECONDEXPANSION :

# include all depfiles with provided modules database: CXX_SRC_MOD_IF_LIST
# depfiles require cmi_mapper function
# CXX_MOD_require1_CMI variables are resolved during secondary expansion
depfiles ::= $(sources:.cpp=.dep)
include $(depfiles)

# Variable modul_rule_template expands to the grouped target rule for module units including recipe.
# input: src - source file name
#        obj - object name
#        cmi - cmi file name
#        dep - depfile name
ifeq ($(CXX_SIMPLE_MAPPING),)
define
modul_rule_template =
$(obj) $(cmi) &: $(src) $(dep) module-map.txt
	g++ -o $(obj) $< -c -fmodule-mapper=module-map.txt ...
endef
else
  modul_rule_template = # rule is provided as Pattern Rule
endif

# provide required module variables CXX_MOD_module_required_CMI
# generate rules + recipes for translation units providing a module
# provide module map, modsources and nomodsources
# let provides the local variables: src, mod, is_if, obj, dep, modi and cmi
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let obj dep modi cmi,$(src:.cpp=.o) $(src:.cpp=.dep) $(subst :,-,$(mod)) $(call cmi_mapper,$(mod),$(src)),\
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
# The dependency file contains the makefile rules for the translation unit and contains the information about provide
# module in form of a variable. The CXX_SRC_MOD_IF_LIST lists:
#    primary output; source; module-provided; is-interface

# (1) The firs rule lists the (non module) prerequisites for the depfiles and dbmfies.
# (2) The second rule lists the required module interfaces if any.
# (3) A variable contains the information about provided module.

# Module Units
# (1)
src.dep : src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
$(call cmi_mapper,module_provided,src.cpp) src.o : $(CXX_MOD_module_required_CMI) ...
# (3)
CXX_SRC_MOD_IF_LIST += src.cpp;module;1

# Non Module Units
# (1)
src.dep : src.cpp header.h ...
# (2) If the unit requires other module units, the second rule is present.
src1.o : $(CXX_MOD_module_required_CMI) ...
# (3)
CXX_SRC_MOD_IF_LIST += src.cpp;-;0
