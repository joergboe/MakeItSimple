# The rules for projects with C++ modules and default module mapping.
# Module dependencies expressed in generated rules.

# With automatic dependency generation based on structured dependency information.
# The CXX_OBJ_SRC_MOD_IF_REQ_LIST lists:
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

# get path of this makefile
my_bin_dir ::= $(dir $(lastword $(MAKEFILE_LIST)))

# collect source files
sources ::= $(wildcard *.cpp)
$(info sources = $(sources))

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
TARGET ?= main
$(TARGET) :

# required compiler options
CXXFLAGS ?= -std=c++20 -fmodules

# rule to generate dependency files with legacy rule and module deps
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	$(CXX) '$<' -MM -MF '$@' -MQ '$@' -fdeps-format=p1689r5 -fdeps-file='$*.ddi' -fdeps-target='$*.o'\
 -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(my_bin_dir)p1689_to_make_tab.sh '$*.ddi' '$@' '$*.o' '$<' # append the module dependencies as table
	@echo

# include depfiles with header and module dependency
CXX_OBJ_SRC_MOD_IF_REQ_LIST ::= # prefer simple variable flavor for the list with provided modules
include $(depfiles)

# TODO: generate variables and modulemap for imported cmi files

# module cache directory
CXX_MODULE_CACHE ?= gcm.cache

# cmi_mapper - map module name or source file name to the cmi file name for project modules
# input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  cmi_mapper = $(CXX_MODULE_CACHE)/$(subst :,-,$1).gcm
else
  cmi_mapper = $(CXX_MODULE_CACHE)/$(src:.cpp=).gcm
endif

# generate variables for cmi file of project modules
# provided variables:
#        src - source file name
#        mod - the module name
#        modi - internal module name (colon is replaced with dash)
#        cmi  - cmi name
modulemap ::= # ensure the simply expanded variable flavor for the output variables
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
  $(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi,$(subst :,-,$(mod)) $(call cmi_mapper,$(mod),$(src)),\
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

# some variables to hide spacial chars
define nl


endef
empty ::=
space ::= $(empty) $(empty)

# write module-map - avoid unnecessary updates
# NOTE: trailing spaces are not allowed
modulemap_subst ::= $(subst ;, ,$(subst $(space),$(nl),$(modulemap)))
modulemap_old ::= $(file < module-map.txt)
ifneq ($(modulemap_old),$(modulemap_subst))
  $(file > module-map.txt,$(modulemap_subst))
endif
# TODO: write empty modulemap

# reqs2cmi - expand all prerequisite modules to cmi file name
# input: reqs - list of prerequisite modules
reqs2cmi = $(foreach mod,$(reqs),$(CXX_MOD_$(subst :,-,$(mod))_CMI))

# template rule for module sources
# input: src - source file name
#        obj - object name
#        dep - depfile name
#        cmi - cmi file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  define modul_rule_template
  $(info generate module rule $(obj) $(cmi) &: $(src) $(reqs2cmi) module-map.txt)

  $$(obj) $$(cmi) : my_obj ::= $$(obj)
  $$(obj) $$(cmi) &: $$(src) $$(dep) $$(reqs2cmi) module-map.txt
	$$(due_to)
	$$(CXX) -o '$$(my_obj)' '$$<' -c -fmodule-mapper=module-map.txt $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	@echo
  endef
else
  define modul_rule_template
  $(info generate module rule $(obj) $(cmi) : $(src) $(reqs2cmi) module-map.txt)

  $$(obj) $$(cmi) : $$(src) $$(dep) $$(reqs2cmi) module-map.txt
  endef
endif

# template rule fragment for non module sources
# input: obj, mod, src, reqs
define no_modul_rule_fragment
$(info generate no module rule $(obj) : $(src) $(dep) $(reqs2cmi) $(if $(reqs),module-map.txt))
$$(obj) : my_map_option ::= $$(if $$(reqs),-fmodule-mapper=module-map.txt)
$$(obj) : $$(src) $$(dep) $$(reqs2cmi) $$(if $$(reqs),module-map.txt)
endef

# generate rules for module units and non module units and variables
# provided variables:
#        src - source file name
#        mod - the module name
#        is_if - is interface (0/1)
#        obj - object name
#        dep - defile name
#        modreq - the required cmi files list
#        cmi  - cmi name (for modules only)
modsources ::= # ensure the simply expanded variable flavor for the output variables
nomodsources ::=
nomodobjects ::=
$(foreach line,$(CXX_OBJ_SRC_MOD_IF_REQ_LIST),\
  $(let obj src mod is_if reqs,$(subst ;, ,$(line)),\
    $(let dep modreq,$(src:.cpp=.dep) $(reqs2cmi),\
      $(if $(subst -,,$(mod)),\
        $(let cmi,$(call cmi_mapper,$(mod),$(src)),\
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

# complete the rules for non module units
$(nomodobjects) : %.o : %.cpp %.dep
	$(due_to)
	$(CXX) -o '$@' '$<' -c $(my_map_option) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo

# generate rules for module sources
ifneq ($(CXX_SIMPLE_MAPPING),)
  %.o $(CXX_MODULE_CACHE)/%.gcm :: %.cpp %.dep module-map.txt
	$(due_to)
	$(CXX) -o '$(<:.cpp=.o)' '$<' -c -fmodule-mapper=module-map.txt $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo
endif

# link all together
objects ::= $(sources:.cpp=.o)
$(TARGET) : $(objects)
	$(due_to)
	$(CXX) -o '$(TARGET)' $(foreach o,$(objects),'$(o)') $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)
	@echo

depfiles_p1689 ::= $(sources:.cpp=.ddi)
.PHONY : clean
clean :
	rm -f '$(TARGET)'
	rm -f *.o
	rm -f *.dep
	rm -f *.ddi
	rm -f module-map.txt
	rm -rf '$(CXX_MODULE_CACHE)'
