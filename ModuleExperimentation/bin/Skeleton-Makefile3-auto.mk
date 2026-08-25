# Skeleton Makefile3-auto.mk

# Difference to Skeleton Makefile1-auto.mk:
# * The depfile substitutes all legacy header dependencies of the translation unit.
# * The rules for module related dependencies are all generated from make. The depfiles contain the
#   rule for the legacy header dependencies and the variable with the module dependencies in CSV style.
#   The CXX_OBJ_SRC_MOD_IF_REQ_LIST list now contains:
#       <primary output; source; module-provided; is-interface[; module-required[...]]>
#
# --------------------------------------------------------------------------

# rule to generate dependency files with legacy rule and module deps
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi ...
	p1689_to_make_tab.sh ... # append the module dependencies as CSV record
	..

# include depfiles with header and module dependency
include $(depfiles)

# Variable cmi_mapper expands to the CMI file name.
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

# provide required module variables CXX_MOD_module_required_CMI
# provide module map, modsources and nomodsources
# let provides the local variables: obj, src, mod, is_if, modi and cmi
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
  $(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi,$(subst :,-,$(mod)) $(call cmi_mapper,$(mod),$(src)),\
        $(eval CXX_MOD_$(modi)_CMI ::= $(cmi))\
        $(eval modulemap += $(mod);$(cmi))\
      )\
    )\
  )\
)

# write module map if necessary
...
ifne(...)
  $(file > module-map.txt,...)
endif

# reqs2cmi - expand all prerequisite modules to cmi file name
# input: reqs - list of prerequisite modules
reqs2cmi = $(foreach mod,$(reqs),$(CXX_MOD_$(subst :,-,$(mod))_CMI))

ifeq ($(CXX_SIMPLE_MAPPING),)
define
modul_rule_template =
$(obj) $(cmi) &: $(src) $(dep) $(reqs2cmi) module-map.txt
	g++ -o $(obj) $$< -c -fmodule-mapper=module-map.txt ...
endef
else
  # provide the rule only, the recipe is added by a Pattern Rule
  define modul_rule_template
$(obj) $(cmi) &: $(src) $(dep) $(reqs2cmi) module-map.txt
  endef
endif

# template rule fragment for non module sources, the recipe is added by a Pattern Rule
define no_modul_rule_fragment
$(obj) : $(src) $(dep) $(reqs2cmi) module-map.txt
endef

# generate rules for all translation units
# provide modsources and nomodsources
# let provides the local variables: obj, src, mod, is_if, dep, modreg and cmi
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
  $(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
    $(let dep modreq,$(src:.cpp=.dep) $(reqs2cmi),\
      $(if $(subst -,,$(mod)),\
        $(let cmi,$(call cmi_mapper,$(mod),$(src)),\
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

# rules for no module sources and simple module mapping
nomodobjects = $(nomodsources:.cpp=.o)
$(nomodobjects) : %.o : %.cpp %.dep
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
# The dependency file contains the makfile rules for the translation unit and contains the information about provide
# module in form of a variable with a CSV record. The CXX_OBJ_SRC_MOD_IF_REQ_LIST lists:
#    primary output; source; module-provided; is-interface[; module-required[...]]

# (1) The firs rule lists the (non module) prerequisites for the depfiles and dbmfies.
# (2) A variable contains the information about provided module.

# Module Units
# (1)
src.dep : src.cpp header.h ...
# (2)
CXX_OBJ_SRC_MOD_IF_REQ_LIST += src.o;src.cpp;module-provided;1;module-required[; ...]

# Non Module Units
# (1)
src.dep : src.cpp header.h ...
# (3)
CXX_OBJ_SRC_MOD_IF_REQ_LIST += src.o;src.cpp;-;0
