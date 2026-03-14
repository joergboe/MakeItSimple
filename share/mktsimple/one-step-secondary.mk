# C++ Modules (standard modules) with g++ or clang++; one step compilation with secondary expansion

min_make_version = 4.4.1
ifneq ($(min_make_version),$(firstword $(sort $(MAKE_VERSION) $(min_make_version))))
  $(warning WARNING: Required make version is $(min_make_version) or higher but version is $(MAKE_VERSION))
endif

# Definitions
SHELL = /bin/bash
.SHELLFLAGS ::= -ec
RMDIR = rm -rf
MKDIR = mkdir -p
RM = rm -f

.SUFFIXES:
.DELETE_ON_ERROR:

empty ::=
define nl ::=


endef

# ensures that 'all' is the default (first target without a dot) goal
all:

# Check command-line options
single_make_options ::= $(firstword -$(MAKEFLAGS))
ifeq (s,$(findstring s,$(single_make_options)))
  silent = 1
else
  silent =
endif

# First info should come before other includes
makefile_this ::= $(lastword $(MAKEFILE_LIST))
ifndef silent
  ifndef MAKE_RESTARTS
    $(info **** Starting makefile: '$(makefile_this)' directory '$(CURDIR)')
  else
    $(info **** Restart # $(MAKE_RESTARTS) of makefile '$(makefile_this)' directory '$(CURDIR)')
  endif
endif

# setup bindir
mktsimple_bindir ::= $(if $(MKTSIMPLE_HOME),$(MKTSIMPLE_HOME)/bin/)

production_goals ::= all deps
header_goals ::= sys-units user-units header-units
cleanup_goals ::= clean purge clean-header-units
action_goals ::= $(production_goals) $(header_goals) $(cleanup_goals)
phony_goals ::= $(action_goals) show
.PHONY: $(phony_goals)

# check goals for cleanup request
goals ::= $(MAKECMDGOALS)
ifeq (,$(goals))
  goals ::= all
endif
cleanup ::= $(filter $(cleanup_goals),$(goals))
header_build ::= $(filter $(header_goals),$(goals))
not_include_deps ::= $(or $(cleanup),$(header_build))
ifdef cleanup
  ifneq (,$(filter-out $(cleanup_goals),$(goals)))
    $(error ERROR: The goals 'clean', 'purge' and 'clean-header-units' must not be used in conjunction with other targets.)
  endif
endif
ifdef header_build
  ifneq (,$(filter-out $(header_goals),$(goals)))
    $(error ERROR: The goals 'sys-units', 'user-units' and 'header-units' must not be used in conjunction with other targets.)
  endif
endif

# Setup configuration with project file...
makefile_defs ::= project.mk
-include $(makefile_defs)

# Check whether it is a g++ or clang++ compiler
cxxpath ::= $(patsubst ./%,%,$(dir $(CXX)))
cxxfile ::= $(notdir $(CXX))
use_clang ::= $(filter clang%,$(cxxfile))
use_gcc ::= $(filter gcc% g++%,$(cxxfile))
ifndef cleanup
  ifeq (,$(or $(use_clang),$(use_gcc)))
    $(error CXX must be gcc%/g++% or clang%/clang++% but is $(CXX))
  endif
endif

# Print verbose if not -s and variable VERBOSE is not null
verbose =
ifndef silent
  ifdef VERBOSE
    verbose = -v
  endif
endif

SRCDIRS ?= .
# get the last path component from the abspath of the current dir as target name
TARGET ?= $(lastword $(subst /, ,$(CURDIR)))
ifdef use_gcc
  CXX_MODULE_CACHE_DIR ::= gcm.cache
else ifdef use_clang
  CXX_MODULE_CACHE_DIR ?= pcm.cache
else
  CXX_MODULE_CACHE_DIR ?= module.cache
endif

ifndef SOURCES
  SOURCES ::= \
    $(patsubst $(CURDIR)/%,%,\
      $(foreach dir,$(SRCDIRS),\
        $(abspath \
          $(wildcard $(dir)/*.cppm) $(wildcard $(dir)/*.cpp)\
         )\
       )\
     )
endif

objects ::= $(addsuffix .o,$(SOURCES))
depfiles ::= $(addsuffix .dep,$(SOURCES))
p1689files ::= $(depfiles:.dep=.ddi)

ifdef use_clang
  system_header_targets ::= $(addprefix $(CXX_MODULE_CACHE_DIR)/,$(addsuffix .pcm,$(CXX_SYSTEM_HEADER_UNITS)))
  user_header_targets ::= $(addprefix $(CXX_MODULE_CACHE_DIR)/,$(addsuffix .pcm,$(CXX_USER_HEADER_UNITS)))
  system_header_file_args ::= $(addprefix -fmodule-file=,$(system_header_targets))
  user_header_file_args ::= $(addprefix -fmodule-file=,$(user_header_targets))
  header_file_args ::= $(system_header_file_args) $(user_header_file_args)
else
  system_header_targets ::= $(addsuffix _target,$(CXX_SYSTEM_HEADER_UNITS))
  user_header_targets ::= $(addsuffix _target,$(CXX_USER_HEADER_UNITS))
endif

# prevent implicit rules search for makefiles
.PHONY: $(makefile_defs) $(makefile_this)

# Must come before other rules
.SECONDEXPANSION:

CXX_SRC_MOD_IF_LIST ::=

ifndef not_include_deps
  include $(depfiles)
endif

# Expands to '1' if param1 and param2 are equal or to the empty string otherwise
# call eq,param1,param2
eq = $(if $(subst $(2),,$(1)),,1)

# Pretty print the src-mod-is_if list
# call pp_src-mod-is_if list
pp_src-mod-is_if = $(foreach line,$1,\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(info $(empty)	src = '$(src)' mod = '$(mod)' is_if = '$(is_if)')\
  )\
)

ifndef silent
  $(info )
  $(info Build target       : '$(TARGET)')
  $(info From sources       : $(foreach x,$(sort $(SOURCES)),'$(x)'))
  $(info In directories     : $(foreach x,$(SRCDIRS),'$(x)'))
  $(info Sytem Header Units : $(CXX_SYSTEM_HEADER_UNITS))
  $(info User Header Units  : $(CXX_USER_HEADER_UNITS))
  ifdef verbose
    $(info Object files            : $(foreach x,$(sort $(objects)),'$(x)'))
    $(info Dependency files        : $(foreach x,$(sort $(depfiles)),'$(x)'))
    $(info Module dependency files : $(foreach x,$(sort $(p1689files)),'$(x)'))
    $(info This makefile        : '$(makefile_this)')
    $(info Sytem Header Targets : $(system_header_targets))
    $(info User Header Targets  : $(user_header_targets))
    $(info CXX_SRC_MOD_IF_LIST:)
    $(call pp_src-mod-is_if,$(CXX_SRC_MOD_IF_LIST))
    $(info MAKE_TERMOUT : $(MAKE_TERMOUT) MAKE_TERMERR : $(MAKE_TERMERR))
    $(info MAKE_VERSION : $(MAKE_VERSION))
    $(info CXX          : $(CXX))
    $(info CXX VERSION  : $(shell $(CXX) --version))
  endif
  $(info )
endif

# Rules section
all: $(TARGET)

deps: $(depfiles)

# Dep files depend on the source and the generated rules with -MQ $*
ifdef use_clang
  scandeps ::= $(cxxpath)clang-scan-deps$(patsubst clang++%,%,$(cxxfile))
  depscan1 = $(scandeps) -o $*.ddi -format=p1689 -- $(CXX) -o $*.o $< -MM -MF $*.dep -MQ $@ -MP -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(header_file_args)
  cmi_extension ::= pcm
else
  depscan1 = $(CXX) $< -MM -MF $*.dep -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
  cmi_extension ::= gcm
endif

$(depfiles): %.dep: %
	@$(RM) $(verbose) $@
	$(depscan1)
	$(mktsimple_bindir)p1689_to_make_sec.sh $*.ddi $< $*.o $@
	$(if $(silent),,@echo -e "Finished dependency scan: $<\n")

# Macro expands to the cmi file name
# Input: mod - module name
cxx_modul_mapper = $(CXX_MODULE_CACHE_DIR)/$(mod).$(cmi_extension)

# module_rule macro expands to a Grouped Targets Rule for a module
# Input: src - source name
#        mod - module name
ifdef use_clang
define module_rule =
$(src).o $(cxx_modul_mapper) &: $(src) $(src).dep | $$(CXX_MODULE_CACHE_DIR)
	$$(if $$(silent),,@$$(RM) $$(verbose) $(src).o $(cxx_modul_mapper))
	$$(CXX) -o $(src).o -fmodule-output='$(cxx_modul_mapper)' -x c++-module $(src) -c -fprebuilt-module-path=$$(CXX_MODULE_CACHE_DIR) -fmodules-reduced-bmi $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) $$(header_file_args)
	$$(if $$(silent),,@echo -e "Finished modul compiling: $(src)\n")
endef
else
define module_rule =
$(src).o $(cxx_modul_mapper) &: $(src) $(src).dep | $$(CXX_MODULE_CACHE_DIR)
	$$(if $$(silent),,@$$(RM) $$(verbose) $(src).o $(cxx_modul_mapper))
	$$(CXX) -o $(src).o $(src) -c $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	$$(if $$(silent),,@echo -e "Finished modul compiling: $(src)\n")
endef
endif

# module_variables expands to variable assignments for module database
# Input: src - source name
#        mod - module name
#        is_if - is interface (0/1)
define module_variables
  CXX_MOD_$(mod)_CMI ::= $(cxx_modul_mapper)
  modules += $(mod)
  modsrcs += $(src)
  $(if $(call eq,$(is_if),1),mod_if_units += $(src))
endef

# Generate rule and variables for a module
# Input: src - source name
#        mod - module name
#        is_if - is interface (0/1)
make_module_artifacts = $(foreach line,$1,\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(silent),,$(info Module '$(mod)' : Generate Module Rule $(src).o $(cxx_modul_mapper) &: $(src) $(src).dep))\
    $(if $(and $(src),$(mod),$(is_if)),\
      ,\
      $(error Inconsistent CXX_SRC_MOD_IF_LIST : '$(src)' '$(mod)' '$(is_if)')\
    )\
    $(if $(filter $(mod),$(modules)),\
      $(error Duplicate module name '$(mod)' in source '$(src)')\
    )\
    $(eval $(module_rule))\
    $(eval $(module_variables))\
  )\
)

# Escape module db for eval
escaped_src_mod_if_list ::= $(subst $$,$$$$,$(CXX_SRC_MOD_IF_LIST))

# Generate module rules and variables
modules ::=
modsrcs ::=
mod_if_units ::=
$(call make_module_artifacts,$(escaped_src_mod_if_list))

nomodsrcs ::= $(filter-out $(modsrcs),$(SOURCES))
nomodobjs ::=$(addsuffix .o,$(nomodsrcs))

ifndef silent
  $(info )
  $(info Module units            : $(foreach x,$(sort $(modsrcs)),'$(x)'))
  $(info Module interface units  : $(foreach x,$(sort $(mod_if_units)),'$(x)'))
  $(info Module names (internal) : $(foreach x,$(sort $(modules)),'$(x)'))
  $(info Not a module            : $(foreach x,$(sort $(nomodsrcs)),'$(x)'))
  ifdef verbose
    $(info Modulname to CMI-file database (CXX_MOD_<modulname>_CMI))
    $(foreach mod,$(modules), $(info $(empty)	$(mod) -> $(CXX_MOD_$(mod)_CMI)))
  endif
  $(info )
endif

# generate objects from non module sources
ifdef use_clang
  nomodobjs_recipe = $(CXX) $(OUTPUT_OPTION) $< -c -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) -fmodules-reduced-bmi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(header_file_args)
else
  nomodobjs_recipe = $(CXX) $(OUTPUT_OPTION) $< -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
endif
$(nomodobjs): %.o: % %.dep
	@$(RM) $(verbose) $@
	$(nomodobjs_recipe)
	$(if $(silent),,@echo -e "Finished building: $<\n")

$(TARGET): $(objects)
	@$(RM) $(verbose) $@
	$(CXX) -o $@ $^ $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $(LDLIBS)
	$(if $(silent),,@echo -e "Finished linking target: $@\n")

# Header units
header-units: sys-units user-units
sys-units: $(system_header_targets)
user-units: $(user_header_targets)

ifdef use_clang
# must not use -fmodules-reduced-bmi
# with -fmodules-reduced-bmi -> error: fatal error: file 'iostream.pcm' is not a valid module file: file doesn't start with precompiled file magic
$(system_header_targets): $(CXX_MODULE_CACHE_DIR)/%.pcm: | $(CXX_MODULE_CACHE_DIR)
	@$(RM) $(verbose) $@
	$(CXX) -o $@ -x c++-header $* -fmodule-header=system -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(if $(silent),,@echo -e "Finished system header translation: $*\n")

$(user_header_targets): $(CXX_MODULE_CACHE_DIR)/%.pcm: % | $(CXX_MODULE_CACHE_DIR)
	-@mkdir $(verbose) $$(dir=; for x in $(subst /, ,$(dir $@)); do if [ -z "$$dir" ]; then dir+="$$x/"; else dir+="$$x/"; echo -n "$$dir "; fi; done)
	@$(RM) $(verbose) $@
	$(CXX) -o $@ -x c++-header $< -fmodule-header=user -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(if $(silent),,@echo -e "Finished user header translation: $*\n")
else
$(system_header_targets): %_target: | $(CXX_MODULE_CACHE_DIR)
	$(CXX) -x c++-system-header $* -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -flang-info-module-cmi -flang-info-include-translate
	$(if $(silent),,@echo -e "Finished system header translation: $*\n")

$(user_header_targets):  %_target: % | $(CXX_MODULE_CACHE_DIR)
	@$(RM) $(verbose) $@
	$(CXX) -x c++-user-header $* -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -flang-info-module-cmi -flang-info-include-translate
	$(if $(silent),,@echo -e "Finished user header translation: $*\n")
endif

$(CXX_MODULE_CACHE_DIR) :
	$(MKDIR) $(verbose) $@
	$(if $(silent),,@echo)

clean-header-units:
	$(if $(silent),,@echo "Header Unit Cleanup")
ifdef use_clang
	$(RM) $(verbose) $(system_header_targets)
	$(RM) $(verbose) $(user_header_targets)
else
	for x in $(CXX_MODULE_CACHE_DIR)/*; do if [[ -d $${x} ]]; then $(RMDIR) $(verbose) "$${x}"; fi; done
endif
	$(if $(silent),,@echo)

clean:
	$(if $(silent),,@echo "Cleanup")
	$(RM) $(verbose) $(TARGET)
	$(RM) $(verbose) $(CXX_MODULE_CACHE_DIR)/*.$(cmi_extension)
	$(RM) $(verbose) $(objects)
	$(RM) $(verbose) $(depfiles)
	$(RM) $(verbose) $(p1689files)
	$(if $(silent),,@echo)

purge: clean clean-header-units
	$(if $(silent),,@echo "Purge")
	$(RM) $(verbose) *.o *.dep *.ddi
	$(RMDIR) $(verbose) $(CXX_MODULE_CACHE_DIR)
	$(if $(silent),,@echo)

ifndef silent
  $(info ***** Start rule processing$(nl))
endif
