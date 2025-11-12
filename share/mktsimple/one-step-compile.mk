# C++ Modules (standard modules) with clang++; one step compilation with separate db generation

min_make_version = 4.4.1
ifneq ($(min_make_version),$(firstword $(sort $(MAKE_VERSION) $(min_make_version))))
  $(warning WARNING: Required make version is $(min_make_version) or higher but version is $(MAKE_VERSION))
endif

# Definitions
SHELL = /bin/bash
.SHELLFLAGS := -ec
RMDIR = rm -rf
MKDIR = mkdir -p
RM = rm -f

.SUFFIXES:
.DELETE_ON_ERROR:

define nl :=


endef

# ensures that 'all' is the default (first target without a dot) goal
all:

# Check command-line options
single_make_options := $(firstword -$(MAKEFLAGS))
ifeq (s,$(findstring s,$(single_make_options)))
  silent = 1
else
  silent =
endif

# First info should come before other includes
makefile_this := $(lastword $(MAKEFILE_LIST))
ifndef silent
  ifndef MAKE_RESTARTS
    $(info **** Starting makefile: '$(makefile_this)' directory '$(CURDIR)')
  else
    $(info **** Restart # $(MAKE_RESTARTS) of makefile '$(makefile_this)' directory '$(CURDIR)')
  endif
endif

# setup bindir
mktsimple_bindir := $(if $(MKTSIMPLE_HOME),$(MKTSIMPLE_HOME)/bin/)

production_goals := all deps
header_goals := sys-units user-units header-units
cleanup_goals := clean purge clean-header-units
action_goals := $(production_goals) $(header_goals) $(cleanup_goals)
phony_goals = $(action_goals) show
.PHONY: $(phony_goals)

# check goals for cleanup request
goals := $(MAKECMDGOALS)
ifeq (,$(goals))
  goals := all
endif
cleanup := $(filter $(cleanup_goals),$(goals))
header_build := $(filter $(header_goals),$(goals))
not_include_deps := $(or $(cleanup),$(header_build))
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
makefile_defs := project.mk
-include $(makefile_defs)

# Check whether it is a g++ or clang++ compiler
cxxpath := $(patsubst ./%,%,$(dir $(CXX)))
cxxfile := $(notdir $(CXX))
use_clang := $(filter clang%,$(cxxfile))
use_gcc := $(filter gcc% g++%,$(cxxfile))
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
  CXX_MODULE_CACHE_DIR := gcm.cache
else ifdef use_clang
  CXX_MODULE_CACHE_DIR ?= pcm.cache
else
  CXX_MODULE_CACHE_DIR ?= module.cache
endif

ifndef SOURCES
  SOURCES := \
    $(patsubst $(CURDIR)/%,%,\
      $(foreach dir,$(SRCDIRS),\
        $(abspath \
          $(wildcard $(dir)/*.cppm) $(wildcard $(dir)/*.cpp)\
         )\
       )\
     )
endif

module_db := module-variables.mk
objects := $(addsuffix .o,$(SOURCES))
depfiles := $(addsuffix .dep,$(SOURCES))
mdepfiles := $(depfiles:.dep=.ddi)

ifdef use_clang
  system_header_targets := $(addprefix $(CXX_MODULE_CACHE_DIR)/,$(addsuffix .pcm,$(CXX_SYSTEM_HEADER_UNITS)))
  user_header_targets := $(addprefix $(CXX_MODULE_CACHE_DIR)/,$(addsuffix .pcm,$(CXX_USER_HEADER_UNITS)))
  #system_header_file_args := $(foreach head,$(CXX_SYSTEM_HEADER_UNITS),'-fmodule-file=<$(head)>=$(CXX_MODULE_CACHE_DIR)/$(head).pcm')
  #user_header_file_args := $(foreach head,$(CXX_USER_HEADER_UNITS),-fmodule-file=$(head)=$(CXX_MODULE_CACHE_DIR)/$(head).pcm)
  #header_file_args := $(addprefix -fmodule-file=,$(system_header_targets)) $(addprefix -fmodule-file=,$(user_header_targets))
  system_header_file_args := $(addprefix -fmodule-file=,$(system_header_targets))
  user_header_file_args := $(addprefix -fmodule-file=,$(user_header_targets))
  header_file_args := $(system_header_file_args) $(user_header_file_args)
else
  system_header_targets := $(addsuffix _target,$(CXX_SYSTEM_HEADER_UNITS))
  user_header_targets := $(addsuffix _target,$(CXX_USER_HEADER_UNITS))
  .PHONY: all sys_units user_units clean purge
endif

# prevent implicit rules search for makefiles
.PHONY: $(makefile_defs) $(makefile_this)

ifndef not_include_deps
  # Must come before other rules
  include $(module_db)

  include $(depfiles)
endif

nomodsrcs := $(filter-out $(CXX_MODULE_SOURCES),$(SOURCES))
nomodobjs :=$(addsuffix .o,$(nomodsrcs))
modsrcs := $(filter $(CXX_MODULE_SOURCES),$(SOURCES))
modobjs := $(addsuffix .o,$(modsrcs))

ifndef silent
  $(info )
  $(info Build target :$(nl)'$(TARGET)')
  $(info From sources :$(nl)$(foreach x,$(sort $(SOURCES)),'$(x)'))
  $(info In directories :$(nl)$(foreach x,$(SRCDIRS),'$(x)'))
  $(info Module interface units :$(nl)$(foreach x,$(sort $(CXX_MODULE_INTERFACE_UNITS)),'$(x)'))
  $(info Module units :$(nl)$(foreach x,$(sort $(CXX_MODULE_SOURCES)),'$(x)'))
  $(info Module names (internal):$(nl)$(foreach x,$(sort $(CXX_MODULES)),'$(x)'))
  $(info Not a module :$(nl)$(foreach x,$(sort $(nomodsrcs)),'$(x)'))
  $(info Sytem Header Units :$(nl)$(CXX_SYSTEM_HEADER_UNITS))
  $(info User Header Units :$(nl)$(CXX_USER_HEADER_UNITS))
  ifdef verbose
    $(info Object files:$(nl)$(foreach x,$(sort $(objects)),'$(x)'))
    $(info Dependency files:$(nl)$(foreach x,$(sort $(depfiles)),'$(x)'))
    $(info Module dependency files:$(nl)$(foreach x,$(sort $(mdepfiles)),'$(x)'))
    $(info Compiled module interface files:$(nl)$(foreach x,$(sort $(CXX_CMI_FILES)),'$(x)'))
    $(info This makefile:$(nl)'$(makefile_this)')
    $(info Sytem Header Targets:$(nl)$(system_header_targets))
    $(info User Header Targets:$(nl)$(user_header_targets))
    $(info )
    $(info Sourcefile to modulname database (CXX_SOURCE2MODULE_<source name>))
    $(foreach src,$(CXX_MODULE_SOURCES),$(eval $(info $(src) -> $(CXX_SOURCE2MODULE_$(src)))))
    $(info Sourcefile to CMI-file database (CXX_SOURCE2CMI_<source name>))
    $(foreach src,$(CXX_MODULE_SOURCES),$(eval $(info $(src) -> $(CXX_SOURCE2CMI_$(src)))))
    $(info Modulname to CMI-file database (CXX_MODULE2CMI_<modulname>))
    $(foreach mod,$(CXX_MODULES),$(eval $(info $(mod) -> $(CXX_MODULE2CMI_$(mod)))))
    $(info MAKE_TERMOUT: $(MAKE_TERMOUT) MAKE_TERMERR: $(MAKE_TERMERR))
    $(info MAKE_VERSION: $(MAKE_VERSION))
  endif
  $(info )
endif

# db check here

# set c++ standard to c++20 if not done otherwise
cppstd :=
ifeq (,$(filter -std=%,$(CXXFLAGS)))
  cppstd := -std=c++20 # One space is appended!
endif

# Rules section
all: $(TARGET)

deps: $(depfiles)

# Dep files depend on the source and the generated rules with -MQ $*
ifdef use_clang
  scandeps := $(cxxpath)clang-scan-deps$(patsubst clang++%,%,$(cxxfile))
  dep_recipe = $(scandeps) -o $*.ddi -format=p1689 -- $(CXX) -o $*.o $< -MMD -MF $*.dep -MQ $*.dep -MQ $*.ddi -MP -c $(cppstd)$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(header_file_args)
  cmi_extension := pcm
else
  dep_recipe = $(CXX) $< -MM -MF '$*.dep' -MQ $*.dep -MQ $*.ddi -MP -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -fmodules $(cppstd)$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
  cmi_extension := gcm
endif

%.dep %.ddi: %
	@$(RM) $(verbose) $*.dep $*.ddi
	$(dep_recipe)
	$(mktsimple_bindir)p1689_to_make.sh $*.ddi $*.o $*.dep
	$(if $(silent),,@echo -e "Finished dependency scan: $<\n")

# module database / variables
$(module_db): $(mdepfiles)
	@$(RM) $(verbose) $@
	$(mktsimple_bindir)p1689_to_make_db.sh $(cmi_extension) $(CXX_MODULE_CACHE_DIR) $@ $^
	$(if $(silent),,@echo -e "Finished database preparation in $@\n")

# generate objects from non module sources
ifdef use_clang
  nomodobjs_recipe = $(CXX) $(OUTPUT_OPTION) $< -c -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) -fmodules-reduced-bmi $(cppstd)$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(header_file_args)
else
  nomodobjs_recipe = $(CXX) $(OUTPUT_OPTION) $< -c -fmodules $(cppstd)$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
endif
$(nomodobjs): %.o: % %.dep
	@$(RM) $(verbose) $@
	$(nomodobjs_recipe)
	$(if $(silent),,@echo -e "Finished building: $<\n")
	

# Rules with Grouped Targets for modules to translate a module source into object and CMI file
ifdef use_clang
# call source-file,cmi-file
define modul_template =
$(1).o $(2) &: $(1) $(1).dep | $(CXX_MODULE_CACHE_DIR)
	$$(if $$(silent),,@$$(RM) $$(verbose) $(1).o $(2))
	$$(CXX) -o $(1).o -fmodule-output='$(2)' -x c++-module $(1) -c -fprebuilt-module-path=$$(CXX_MODULE_CACHE_DIR) -fmodules-reduced-bmi $$(cppstd)$$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) $$(header_file_args)
	$$(if $$(silent),,@echo -e "Finished modul compiling: $(1)\n")
endef
else
define modul_template =
$(1).o $(2) &: $(1) $(1).dep | $(CXX_MODULE_CACHE_DIR)
	$$(if $$(silent),,@$$(RM) $$(verbose) $(1).o $(2))
	$$(CXX) -o $(1).o $(1) -c -fmodules $$(cppstd)$$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	$$(if $$(silent),,@echo -e "Finished modul compiling: $(1)\n")
endef
endif
# Generate rules for all modules
$(foreach src,$(modsrcs),$(eval $(call modul_template,$(src),$$(CXX_SOURCE2CMI_$(src)))))

$(TARGET): $(modobjs) $(nomodobjs)
	@$(RM) $(verbose) $@
	$(CXX) -o $@ $^ $(cppstd)$(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $(LDLIBS)
	$(if $(silent),,@echo -e "Finished linking target: $@\n")

# Header units
header-units: sys-units user-units
sys-units: $(system_header_targets)
user-units: $(user_header_targets)

ifdef use_clang
  # must not use -fmodules-reduced-bmi
  # with -fmodules-reduced-bmi -> error: fatal error: file 'iostream.pcm' is not a valid module file: file doesn't start with precompiled file magic
  $(system_header_targets): $(CXX_MODULE_CACHE_DIR)/%.pcm: | $(CXX_MODULE_CACHE_DIR)
	$(CXX) -o $@ -x c++-header $* -fmodule-header=system -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) $(cppstd)$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(if $(silent),,@echo -e "Finished system header translation: $*\n")

  $(user_header_targets): $(CXX_MODULE_CACHE_DIR)/%.pcm: % | $(CXX_MODULE_CACHE_DIR)
	-@mkdir $(verbose) $$(dir=; for x in $(subst /, ,$(dir $@)); do dir+="$$x/"; echo -n "$$dir "; done)
	$(CXX) -o $@ -x c++-header $< -fmodule-header=user -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) $(cppstd)$(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(if $(silent),,@echo -e "Finished user header translation: $*\n")
else
  # Template for header units
  # call header_template,header_unit,sytem|user
define header_template =
$(1)_target: | $$(CXX_MODULE_CACHE_DIR)
	$$(CXX) -x c++-$(2)-header $(1) -c -fmodules $$(cppstd)$$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) -flang-info-module-cmi -flang-info-include-translate
endef

  # Generate rules for system header units
  $(foreach unit,$(CXX_SYSTEM_HEADER_UNITS),$(eval $(call header_template,$(unit),system)))

  # Generate rules for user header units
  $(foreach unit,$(CXX_USER_HEADER_UNITS),$(eval $(call header_template,$(unit),user)))
endif

$(CXX_MODULE_CACHE_DIR) :
	@$(MKDIR) $(verbose) $@
	$(if $(silent),,@echo)

clean-header-units:
	$(if $(silent),,@echo "Header Unit Cleanup")
	$(RM) $(verbose) $(system_header_targets)
	$(RM) $(verbose) $(user_header_targets)
	$(if $(silent),,@echo)

clean:
	$(if $(silent),,@echo "Cleanup")
	$(RM) $(verbose) $(TARGET) $(CXX_CMI_FILES)
	$(RM) $(verbose) $(nomodobjs) $(modobjs)
	$(if $(silent),,@echo)

purge: clean clean-header-units
	$(if $(silent),,@echo "Purge")
	$(RM) $(verbose) $(depfiles)
	$(RM) $(verbose) $(mdepfiles)
	$(RM) $(verbose) $(module_db)
	$(RM) $(verbose) *.o *.dep *.ddi
	$(RMDIR) $(verbose) $(CXX_MODULE_CACHE_DIR)
	$(if $(silent),,@echo)

ifndef silent
  $(info ***** Start rule processing$(nl))
endif
