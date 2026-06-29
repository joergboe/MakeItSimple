# C++ Modules (standard modules) with g++ or clang++; one step compilation with
# * immediately generated module db (secondary expansion)
# * separate module db generated as file (FILE_MOD_DB=1)

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

# Check for command-line option -s
single_make_options ::= $(firstword -$(MAKEFLAGS))
ifeq (s,$(findstring s,$(single_make_options)))
  silent = 1
else  # Define the empty variable 'silent' to avoid undefined variables warnings with --warn-undefined-variables
  silent =
endif

# Print verbose if not -s and variable VERBOSE is not null
verbose =
ifndef silent
  ifdef VERBOSE
    ifneq ($(strip $(VERBOSE)),)
      verbose = -v
    endif
  endif
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

# setup make it simple bin dir
mktsimple_bindir ::= $(if $(MKTSIMPLE_HOME),$(MKTSIMPLE_HOME)/bin/)

production_goals ::= all deps
header_goals ::= sys-units user-units header-units
cleanup_goals ::= clean purge clean-header-units
action_goals ::= $(production_goals) $(header_goals) $(cleanup_goals)
phony_goals ::= $(action_goals) show
.PHONY: $(phony_goals)

# check goals
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

# get the last path component from the abspath of the current dir as target name
TARGET ?= $(lastword $(subst /, ,$(CURDIR)))
ifdef use_gcc
  CXX_MODULE_CACHE_DIR ::= gcm.cache
else ifdef use_clang
  CXX_MODULE_CACHE_DIR ?= pcm.cache
else
  CXX_MODULE_CACHE_DIR ?= module.cache
endif

# Single quote list
# call singl_quote,list
singl_quote = $(foreach x,$1,'$(x)')

# Expands to non-empty string if param1 and param2 are not equal or to the empty string otherwise
# call neq,param1,param2
neq = $(or $(subst $2,,$1),$(subst $1,,$2))

# Make sure the string ends with a forward slash.
# call ensure_dir_end dir_list
ensure_dir_end = $(foreach var,$1,$(if $(filter %/,$(var)),$(var),$(var)/))

# Add directory prefix if prefix differs from ./
# Requires a slash at the end of prefix
# call add_dir_prefix,dir_prefix,list
add_dir_prefix = $(if $(subst ./,,$1),$(foreach dir,$2,$1$(dir)),$2)

# call filter_out_dot_dir,dir
filter_out_dot_dir = $(subst ./,,$1)

# Convert a directory string list to a canonicalized relative dir
# call canon_rel,dirs
canon_rel = $(shell realpath -ms --relative-to=$(CURDIR) $1)$\
  $(if $(subst 0,,$(.SHELLSTATUS)),$(warning realpath returns failure $(.SHELLSTATUS)))

# Exit if dir is absolute and expand to dir
# call exit_if_abs,dir
exit_if_abs = $(if $(patsubst /%,,$1),$1,$(error '$1' must be relative to $(CURDIR)))

# Warn if dir is absolute and expand to dir
# call warn_if_abs,dir
warn_if_abs = $(if $(patsubst /%,,$1),$1,$(warning '$1' is converted to relative )$1)

# Determine sources and source dirs
# srcdirs_int: unique list of canonicalized relative dir ending with slash
# sources_int: unique list of converted to canonicalized relative path; ./ is removed
ifeq ($(strip $(SOURCES)),)
  ifeq ($(strip $(SRCDIRS)),)
    SRCDIRS = src/
  endif
  srcdirs_int ::= $(sort $(call ensure_dir_end,$(call canon_rel,$(foreach dir,$(SRCDIRS),$(call warn_if_abs,$(dir))))))
  sources_int ::= $(foreach var,$(srcdirs_int),$\
    $(wildcard $(call filter_out_dot_dir,$(var))*.cppm)\
    $(wildcard $(call filter_out_dot_dir,$(var))*.cpp)\
    $(wildcard $(call filter_out_dot_dir,$(var))*.cc)$\
  )
else
  ifeq ($(strip $(SRCDIRS)),)
    sources_int ::= $(sort $(call canon_rel,$(foreach dir,$(SOURCES),$(call warn_if_abs,$(dir)))))
    srcdirs_int ::= $(sort $(dir $(sources_int)))
  else
    $(error SRCDIRS and SOURCES are defined! One of SRCDIRS and SOURCES is sufficient.)
  endif
endif

# bindir_int: relative path ending with slash; empty if current dir
# builddir_int: relative path ending with slash; empty if current dir
BINDIR ?= bin
bindir_int ::= $(call filter_out_dot_dir,$(call ensure_dir_end,$(call exit_if_abs,$(BINDIR))))
BUILDDIR ?= build
builddir_int ::= $(call filter_out_dot_dir,$(call ensure_dir_end,$(call exit_if_abs,$(BUILDDIR))))

# bindir and builddir with ./ removed
dirs_to_remove ::= $(strip $(bindir_int) $(builddir_int))

builddirs ::= $(if $(builddir_int),$\
  $(foreach dir,$(srcdirs_int),$\
    $(if $(subst ./,,$(dir)),$\
      $(builddir_int)$(dir)$\
    ,$\
      $(builddir_int)$\
    )$\
  )$\
,$\
  $(srcdirs_int)$\
)

# remove ./ from  builddirs list
builddirs_reduced ::= $(strip $(call filter_out_dot_dir,$(filter-out $(builddir_int),$(builddirs))))

objects ::= $(addprefix $(builddir_int),$(addsuffix .o,$(sources_int)))
depfiles ::= $(addprefix $(builddir_int),$(addsuffix .dep,$(sources_int)))
p1689files ::= $(depfiles:.dep=.ddi)

module_db ::= module-variables.mk

ifdef use_clang
  system_header_targets ::= $(addprefix $(CXX_MODULE_CACHE_DIR)/,$(addsuffix .pcm,$(CXX_SYSTEM_HEADER_UNITS)))
  user_header_targets ::= $(addprefix $(CXX_MODULE_CACHE_DIR)/,$(addsuffix .pcm,$(CXX_USER_HEADER_UNITS)))
  system_header_file_args ::= $(foreach var,$(system_header_targets),-fmodule-file='$(var)')
  user_header_file_args ::= $(foreach var,$(user_header_targets),-fmodule-file='$(var)')
  header_file_args ::= $(system_header_file_args) $(user_header_file_args)
else
  system_header_targets ::= $(addsuffix _target,$(CXX_SYSTEM_HEADER_UNITS))
  user_header_targets ::= $(addsuffix _target,$(CXX_USER_HEADER_UNITS))
endif

# prevent implicit rules search for makefiles
.PHONY: $(makefile_defs) $(makefile_this)

# Include required variables
CXX_SRC_MOD_IF_LIST ::=
ifdef FILE_MOD_DB
  ifndef not_include_deps
    include $(builddir_int)$(module_db)
  endif
else
.SECONDEXPANSION:
  ifndef not_include_deps
    include $(depfiles)
  endif
endif

# Pretty print the src-mod-is_if list
# call pp_src-mod-is_if list
pp_src-mod-is_if = $(foreach line,$1,\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(info $(empty)	src = '$(src)' mod = '$(mod)' is_if = '$(is_if)')\
  )\
)

ifndef silent
  $(info )
  $(info Build target       : '$(bindir_int)$(TARGET)')
  $(info From sources       : $(call singl_quote,$(sources_int)))
  $(info In directories     : $(call singl_quote,$(srcdirs_int)))
  $(info Sytem Header Units : $(CXX_SYSTEM_HEADER_UNITS))
  $(info User Header Units  : $(CXX_USER_HEADER_UNITS))
  ifdef FILE_MOD_DB
    $(info Build module database in file $(module_db))
else
    $(info Build with embedded module database and Secondary Expansion)
  endif
  ifdef verbose
    $(info Binary directory        : '$(bindir_int)'$(if $(bindir_int),, - current directory))
    $(info Build directory         : '$(builddir_int)'$(if $(builddir_int),, - current directory))
    $(info Build directories list  : $(call singl_quote,$(builddirs)))
    $(info Object files            : $(call singl_quote,$(objects)))
    $(info Dependency files        : $(call singl_quote,$(depfiles)))
    $(info Module dependency files : $(call singl_quote,$(p1689files)))
    $(info This makefile        : '$(makefile_this)')
    $(info Sytem Header Targets : $(system_header_targets))
    $(info User Header Targets  : $(user_header_targets))
    ifdef FILE_MOD_DB
      $(info Module database file : $(module_db))
    endif
    $(info CXX_SRC_MOD_IF_LIST:)
    $(call pp_src-mod-is_if,$(CXX_SRC_MOD_IF_LIST))
    $(info MAKE_TERMOUT : $(MAKE_TERMOUT) MAKE_TERMERR : $(MAKE_TERMERR))
    $(info MAKE_VERSION : $(MAKE_VERSION))
    $(if $(use_gcc),$(info Use gcc))
    $(if $(use_clang),$(info Use clang))
    $(info cxxpath = '$(cxxpath)'  cxxfile = '$(cxxfile)')
    $(info CXX          : $(CXX))
    $(info CXX VERSION  : $(shell $(CXX) --version))
  endif
  $(info )
endif

# Rules section
all: $(bindir_int)$(TARGET)

deps: $(depfiles)

ifdef FILE_MOD_DB
  depflags = -MM -MF $(builddir_int)$*.dep -MP -MQ $(builddir_int)$*.dep -MQ $(builddir_int)$*.ddi
else
  depflags = -MM -MF $(builddir_int)$*.dep -MP -MQ $@
endif

# Dep files depend on the source and the generated rules with -MQ $*
ifdef use_clang
  scandeps ::= $(cxxpath)clang-scan-deps$(if $(filter clang++%,$(cxxfile)),$\
      $(patsubst clang++%,%,$(cxxfile))$\
    ,$\
      $(patsubst clang%,%,$(cxxfile))$\
    )
  depscan1 = $(scandeps) -o '$(builddir_int)$*.ddi' -format=p1689 -- $(CXX) -o '$(builddir_int)$*.o' '$<' $(depflags)\
    $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(header_file_args)
  cmi_extension ::= pcm
else
  depscan1 = $(CXX) '$<' $(depflags) -fdeps-format=p1689r5 -fdeps-file='$(builddir_int)$*.ddi'\
    -fdeps-target='$(builddir_int)$*.o' $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
  cmi_extension ::= gcm
endif

ifdef FILE_MOD_DB
# depfile production
$(builddir_int)%.dep $(builddir_int)%.ddi &: % | $(call filter_out_dot_dir,$(dir $(builddir_int)%))
	@$(RM) $(verbose) '$*.dep' '$*.ddi'
	$(depscan1)
	$(mktsimple_bindir)p1689_to_make.sh '$(builddir_int)$*.ddi' '$(builddir_int)$*.o' '$(builddir_int)$*.dep'
	$(if $(silent),,@echo -e "Finished dependency scan: '$<'\n")

# module database / variables
$(builddir_int)$(module_db): $(p1689files) | $(builddir_int)
	@$(RM) $(verbose) '$@'
	$(mktsimple_bindir)p1689_to_make_db.sh '$@' '.ddi' '' '.o' '$(builddir_int)' $(call singl_quote,$^)
	$(if $(silent),,@echo -e "Finished database preparation in '$@'\n")
else
# depfile production
$(depfiles): $(builddir_int)%.dep: % | $(call filter_out_dot_dir,$(dir $(builddir_int)%))
	@$(RM) $(verbose) '$@'
	$(depscan1)
	$(mktsimple_bindir)p1689_to_make_sec.sh '$(builddir_int)$*.ddi' '$<' '$(builddir_int)$*.o' '$@'
	$(if $(silent),,@echo -e "Finished dependency scan: '$<'\n")
endif


# cxx_module_mapper macro expands to the cmi file name
# Input: mod - module name
cxx_module_mapper = $(CXX_MODULE_CACHE_DIR)/$(mod).$(cmi_extension)

# module_rule macro expands to a Grouped Targets Rule for a module
# Input: src - source name
#        mod - module name
ifdef use_clang
define module_rule =
$(builddir_int)$(src).o $(cxx_module_mapper) &: $(src) $(builddir_int)$(src).dep | $$(CXX_MODULE_CACHE_DIR)
	$$(if $$(silent),,@$$(RM) $$(verbose) '$(builddir_int)$(src).o' '$(cxx_module_mapper)')
	$$(CXX) -o '$(builddir_int)$(src).o' -fmodule-output='$(cxx_module_mapper)' -x c++-module '$(src)' -c\
	 -fprebuilt-module-path='$$(CXX_MODULE_CACHE_DIR)' -fmodules-reduced-bmi $$(CXXFLAGS) $$(CPPFLAGS)\
	 $$(TARGET_ARCH) $$(header_file_args)
	$$(if $$(silent),,@echo -e "Finished module compiling: $(src)\n")
endef
else
define module_rule =
$(builddir_int)$(src).o $(cxx_module_mapper) &: $(src) $(builddir_int)$(src).dep | $$(CXX_MODULE_CACHE_DIR)
	$$(if $$(silent),,@$$(RM) $$(verbose) '$(builddir_int)$(src).o' '$(cxx_module_mapper)')
	$$(CXX) -o '$(builddir_int)$(src).o' '$(src)' -c $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH)
	$$(if $$(silent),,@echo -e "Finished module compiling: '$(src)'\n")
endef
endif

# module_variables expands to variable assignments for module database
# Input: src - source name
#        mod - module name
#        is_if - is interface (0/1)
define module_variables
  CXX_MOD_$(mod)_CMI ::= $(cxx_module_mapper)
  modules += $(mod)
  modsrcs += $(src)
  $(if $(call neq,$(is_if),0),mod_if_units += $(src))
endef

# Generate rule and variables for a module
# Input: src - source name
#        mod - module name
#        is_if - is interface (0/1)
make_module_artifacts = $(foreach line,$1,\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(silent),,$(info Module '$(mod)' : Generate Module Rule $(src).o $(cxx_module_mapper) &: $(src) $(src).dep))\
    $(if $(and $(src),$(mod),$(is_if)),\
      ,\
      $(error Inconsistent CXX_SRC_MOD_IF_LIST : '$(src)' '$(mod)' '$(is_if)')\
    )\
    $(if $(filter $(mod),$(modules)),\
      $(warning Duplicate module name '$(mod)' in source '$(src)')\
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

nomodsrcs ::= $(filter-out $(modsrcs),$(sources_int))
nomodobjs ::= $(call add_dir_prefix,$(builddir_int),$(addsuffix .o,$(nomodsrcs)))

ifndef silent
  $(info )
  ifdef CXX_SRC_MOD_IF_LIST
    $(info Module units            : $(foreach x,$(sort $(modsrcs)),'$(x)'))
    $(info Module interface units  : $(foreach x,$(sort $(mod_if_units)),'$(x)'))
    $(info Module names (internal) : $(foreach x,$(sort $(modules)),'$(x)'))
    $(info Not a module            : $(foreach x,$(sort $(nomodsrcs)),'$(x)'))
    ifdef verbose
      $(info Modulname to CMI-file database (CXX_MOD_<module name>_CMI))
      $(foreach mod,$(modules), $(info $(empty)	$(mod) -> $(CXX_MOD_$(mod)_CMI)))
    endif
  else
    $(info No modules)
  endif
  $(info )
endif

ifdef FILE_MOD_DB
  # Include dependency rules after variable definitions
  ifndef not_include_deps
    include $(depfiles)
  endif
endif

# generate objects from non module sources
ifdef use_clang
  nomodobjs_recipe = $(CXX) $(OUTPUT_OPTION) '$<' -c -fprebuilt-module-path='$(CXX_MODULE_CACHE_DIR)'\
    -fmodules-reduced-bmi $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(header_file_args)
else
  nomodobjs_recipe = $(CXX) $(OUTPUT_OPTION) '$<' -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
endif
$(nomodobjs): $(builddir_int)%.o: % $(builddir_int)%.dep
	@$(RM) $(verbose) '$@'
	$(nomodobjs_recipe)
	$(if $(silent),,@echo -e "Finished building: '$<'\n")

$(bindir_int)$(TARGET): $(objects) | $(bindir_int)
	@$(RM) $(verbose) '$@'
	$(CXX) -o '$@' $(call singl_quote,$^) $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $(LDLIBS)
	$(if $(silent),,@echo -e "Finished linking target: '$@'\n")

# Header units
header-units: sys-units user-units
sys-units: $(system_header_targets)
user-units: $(user_header_targets)

ifdef use_clang
# must not use -fmodules-reduced-bmi
# with -fmodules-reduced-bmi -> error:
# fatal error: file 'iostream.pcm' is not a valid module file: file doesn't start with precompiled file magic
$(system_header_targets): $(CXX_MODULE_CACHE_DIR)/%.pcm: | $(CXX_MODULE_CACHE_DIR)
	@$(RM) $(verbose) '$@'
	$(CXX) -o '$@' -x c++-header '$*' -fmodule-header=system -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) -MD -MP -MF '$*.d'\
	 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(if $(silent),,@echo -e "Finished system header translation: '$*'\n")

$(user_header_targets): $(CXX_MODULE_CACHE_DIR)/%.pcm: % | $(CXX_MODULE_CACHE_DIR)
	@$(MKDIR) $(verbose) $(dir $@)
	@$(RM) $(verbose) '$@'
	$(CXX) -o '$@' -x c++-header '$<' -fmodule-header=user -fprebuilt-module-path=$(CXX_MODULE_CACHE_DIR) -MD -MP -MF '$*.d'\
	 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	$(if $(silent),,@echo -e "Finished user header translation: '$*'\n")
else
$(system_header_targets): %_target: | $(CXX_MODULE_CACHE_DIR)
	$(CXX) -x c++-system-header '$*' -c -MD -MP -fdeps-format=p1689r5 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -flang-info-module-cmi\
	 -flang-info-include-translate
	$(if $(silent),,@echo -e "Finished system header translation: '$*'\n")

$(user_header_targets):  %_target: % | $(CXX_MODULE_CACHE_DIR)
	@$(RM) $(verbose) '$@'
	$(CXX) -x c++-user-header '$*' -c -MD -MP -fdeps-format=p1689r5 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -flang-info-module-cmi\
	 -flang-info-include-translate
	$(if $(silent),,@echo -e "Finished user header translation: '$*'\n")
endif

$(CXX_MODULE_CACHE_DIR) :
	$(MKDIR) $(verbose) '$@'
	$(if $(silent),,@echo)

$(builddirs_reduced): | $(builddir_int)
	$(MKDIR) $(verbose) '$@'
	$(if $(silent),,@echo)

$(builddir_int):
	$(MKDIR) $(verbose) '$(builddir_int)'
	$(if $(silent),,@echo)

$(bindir_int):
	$(MKDIR) $(verbose) '$(bindir_int)'
	$(if $(silent),,@echo)

clean-header-units:
	$(if $(silent),,@echo "Header Unit Cleanup")
ifdef use_clang
	$(RM) $(verbose) $(foreach var,$(system_header_targets),'$(var)')
	$(RM) $(verbose) $(foreach var,$(user_header_targets),'$(var)')
else
	for x in $(CXX_MODULE_CACHE_DIR)/*; do if [[ -d $${x} ]]; then $(RMDIR) $(verbose) "$${x}"; fi; done
endif
	$(if $(silent),,@echo)

clean:
	$(if $(silent),,@echo "Cleanup")
	$(RM) $(verbose) '$(bindir_int)$(TARGET)'
	$(RM) $(verbose) $(CXX_MODULE_CACHE_DIR)/*.$(cmi_extension)
	$(RM) $(verbose) $(call singl_quote,$(objects))
	$(RM) $(verbose) $(call singl_quote,$(depfiles))
	$(RM) $(verbose) $(call singl_quote,$(p1689files))
ifdef FILE_MOD_DB
	$(RM) $(verbose) '$(builddir_int)$(module_db)'
endif
	$(if $(silent),,@echo)

purge: clean clean-header-units
	$(if $(silent),,@echo "Purge")
	$(RM) $(verbose) *.o *.dep *.ddi
	$(RM) $(verbose) '$(builddir_int)$(module_db)'
ifdef dirs_to_remove
	$(RMDIR) $(verbose) $(call singl_quote,$(dirs_to_remove))
endif
	$(RMDIR) $(verbose) '$(CXX_MODULE_CACHE_DIR)' 'gcm.cache' 'pcm.cache' 'module.cache'
	$(if $(silent),,@echo)

ifndef silent
  $(info ***** Start rule processing$(nl))
endif
