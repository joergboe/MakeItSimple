# The rules for projects with C++ modules using secondary expansion
# Variables are used to express the module dependencies in prerequisites.
# A variable like CXX_MOD_modulname_CMI substitutes the cmi file name by the module name.
# Database variables and dependency rules are generated in dep files.

# With automatic dependency generation based on structured dependency information.
# The CXX_SRC_MOD_IF_LIST lists:
#    primary output; source; module-provided; is-interface
# The depfile substitutes all legacy header dependencies of an translation unit.
# Grouped Target Rules for module units are generated with 'eval'.

# The automatic variable $? is fixed because the grouped rule prerequisites are complete.

# The makefile implements 2 custom module mappings:
#    If CXX_MAP_MOD_2_SRC_NAME is undefined the name of the cmi file is         modulecache/<modulname>.gcm
#    If CXX_MAP_MOD_2_SRC_NAME has a nonempty value the name of the cmi file is modulecache/<sourcefile>.gcm

# With CXX_MAP_MOD_2_SRC_NAME=1:
# Problem with grouped pattern rule dependency propagation. (delete src1.o src2.o)

$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) in directory $(CURDIR))

# get path of this makefile
my_bin_dir ::= $(dir $(lastword $(MAKEFILE_LIST)))

# collect source files
sources ::= $(wildcard *.cpp)
$(info sources = $(sources))

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

.SECONDEXPANSION :

# default target
TARGET ?= main
$(TARGET) :

# required compiler options
CXXFLAGS ?= -std=c++20 -fmodules

# rule to generate dependency files
depfiles ::= $(sources:.cpp=.dep)
$(depfiles) : %.dep: %.cpp
	$(due_to)
	$(CXX) '$<' -MM -MF '$@' -MQ '$@' -fdeps-format=p1689r5 -fdeps-file='$*.ddi' -fdeps-target='$*.o'\
 -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(my_bin_dir)p1689_to_make_sec.sh '$*.ddi' '$@' '$*.o' '$<' # rewrite dependencies for secondary exp. and append module deps
	@echo

# module cache directory
CXX_MODULE_CACHE ?= gcm.cache

# cmi_mapper - map module name or source file name to the cmi file name for project modules
# input: 1 - module name
#        2 - source file name
ifeq ($(CXX_MAP_MOD_2_SRC_NAME),)
  cmi_mapper = $(CXX_MODULE_CACHE)/$(subst :,-,$1).gcm
else
  cmi_mapper = $(CXX_MODULE_CACHE)/$(src:.cpp=).gcm
endif

# include all depfiles with provided modules database: CXX_SRC_MOD_IF_LIST
# depfiles require cmi_mapper function
# CXX_MOD_require1_CMI variables are resolved during secondary expansion
CXX_SRC_MOD_IF_LIST ::= # prefer simple variable favor for the list with provided modules
include $(depfiles)

# template rule for module sources
# input: src - source file name
#        obj - object name
#        dep - depfile name
#        cmi - cmi file name
ifeq ($(CXX_MAP_MOD_2_SRC_NAME),)
  define modul_rule_template
  $(info generate module rule $(obj) $(cmi) &: $(subst $$,$$$$,$(src) $(dep)) module-map.txt)

  $$(obj) $$(cmi) : my_obj ::= $$(obj)
  $$(obj) $$(cmi) &: $$(subst $$$$,$$$$$$$$,$$(src) $$(dep))
	$$(due_to)
	$$(CXX) -o '$$(my_obj)' '$$<' -c -fmodule-mapper=module-map.txt $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	@echo
  endef
else
  modul_rule_template =
endif

# TODO: generate variables and modulemap for imported cmi files

# generate rules for module sources, module variables and module map and check for duplicate module
# provided variables:
#        src - source file name
#        mod - the module name
#        is_if - is interface (0/1)
#        modi - internal module name (colon is replaced with dash)
#        cmi  - cmi name
#        obj - object name
#        dep - defile name
modsources ::= # generate rules for module sources and module variables for the output variables
nomodsources ::=
modulemap ::=
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi obj dep,$(subst :,-,$(mod)) $(call cmi_mapper,$(mod),$(src)) $(src:.cpp=.o) $(src:.cpp=.dep),\
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
# TODO: keep going for duplicate modules check
$(info nomodsources = $(nomodsources))
$(info )

# TODO: generate variables and modulemap for imported cmi files

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

# generate rules for no module sources
nomodobjects ::= $(nomodsources:.cpp=.o)
$(nomodobjects) : %.o : %.cpp %.dep module-map.txt
	$(due_to)
	$(CXX) -o '$@' '$<' -c -fmodule-mapper=module-map.txt $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo

# generate rules for module sources
ifneq ($(CXX_MAP_MOD_2_SRC_NAME),)
  %.o $(CXX_MODULE_CACHE)/%.gcm :: %.cpp %.dep module-map.txt
	$(due_to)
	$(CXX) -o '$(<:.cpp=.o)' '$<' -c -fmodule-mapper=module-map.txt $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	@echo
endif

# link all together
objects ::= $(sources:.cpp=.o)
# prepare objects for second expansion
$(TARGET) : $(subst $$,$$$$,$(objects))
	$(due_to)
	$(CXX) -o '$(TARGET)' $(foreach o,$(objects),'$(o)') $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)
	@echo

.PHONY : clean
clean :
	rm -f '$(TARGET)'
	rm -f *.o
	rm -f *.dep
	rm -f *.dep~
	rm -f *.ddi
	rm -f module-map.txt
	rm -rf '$(CXX_MODULE_CACHE)'
