# Prepare the help string if required
ifneq (,$(findstring help,$(MAKECMDGOALS)))
  define helpstring =

This make script builds one executable from all %.cpp and %.cc source files in the current/project
directory and creates a JSON Compilation Database ($(compile_database_name)) for the clang language
server.
The script supports 2 Build Modes (run and debug) and 4 Warning levels.
The script keeps track of the last used configuration in a file ($(last_config_store_name)). During
startup, the script checks the current build configuration. If a change in the buid configuration
has been detected, a complete build of all targets is initiated.


Synopsis:
    make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [..] [goal ..]
  or
    [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [..] make [make-options] [goal ..]


Goals:
  all       Default goal - Build or update the target executable if outdated and build or update the
            JSON compilation database if neccessary.
  build     Build or update the target executable.
  compdb    Build or update the JSON Compilation Database if neccessary.
  clean     Clean up the target executable and all build artefacts.
  cleanall  Clean up all generated executable, build artefacts, the Compilation Database and the
            configuration store.
  info      Print project info.
  help      Print this help text.
  %.o       Build this object file if a coresponding source file exists.

Files:
  Makefile        This make script
  $(makefile_defs)      This optional script contains the project customizations.
  $$(MAKEFILE_WARN) If the default warning options are not sufficient, this optional file can be
                    used to define specific warning options and will be included from Makefile.

Optional customization variables:
  TARGET              Name of the executable to build. Default value is the last path component of
                      this Makefile.
  INCSYSDIRS:         Space separated list of external include directories used with compiler option
                      -I. Default: empty.
  WARN_LEVEL:         Warning level set 0 .. 3. Default: 2
  MAKEFILE_WARN:      The name of the file with specific warning options. Default: 'warnings.mk'
  BUILD_MODE:         Build mode set to 'run' or 'debug'. Default: 'debug'
  COMP_FLAGS_RUN:     Compiler optimization level and debug option with BUILD_MODE = run.
                      Default: -O2 -g1 (clang: -Og -gline-tables-only)
  COMP_FLAGS_DEBUG:   Compiler optimization level and debug option with BUILD_MODE = debug.
                      Default: -Og -g3
  CPPFLAGS:           Extra compiler preprocessor options.
  CXXFLAGS:           Extra c++ compiler options (use for linker and compiler).
  TARGET_ARCH:        Target specific flags.
  LDFLAGS:            Extra linker options, such as -L.
  LDLIBS:             Space separated list of libraries given to the linker.
  CXX                 The compiler command to be used. Default: 'g++'
  DISABLE_CONFIG_CHECK: If set to anything other than the empty string, the configuration check is
                      disabled.

Description:
  This make script builds or updates one executable from all %.cpp and %.cc source files in the
  current project directory. The name of the executable is defined through variable TARGET and the
  default is the last component of the directory which contains this Makefile.

  If a 'production goal' (all compdb %.o..) runs and a configuration change has bee detected the
  compilation database is automatically created or updated.

  If variable BUILD_MODE is not set or has the value debug, the executables are build with debug
  information included.
  If variable BUILD_MODE equals 'run', optimized executables without debug information are built.

  The variable WARN_LEVEL can assign warning levels from 0 .. 3.
  The default warning level is 2 and activates a comprehensive set of warnings (for gcc and clang).

  By default the g++ compiler is used. To use a different compiler, set variable CXX. E.g 'CXX=clang++'

  Use the CXXFLAGS variable to change the c++ language standard. E.g. 'CXXFLAGS=-std=c++11'.

  If parallel execution is requested (-j n), the script disallowes the congruent execution of clean-
  and production-goals.

Some useful make-options:
  -h, --help                      Display help.
  -j [N], --jobs[=N]              Allow N jobs at once; infinite jobs with no arg.
  -k, --keep-going                Continue as much as possible after an error.
  -B, --always-make               Unconditionally make all targets.
  -r, --no-builtin-rules          Disable the built-in implicit rules.
  -s, --silent, --quiet           Don't echo recipes.
  -O[TYPE], --output-sync[=TYPE]  Synchronize output of parallel jobs by TYPE (none|line|target|recurse).

  endef
endif
# Prepare the info string if required
ifneq (,$(findstring info,$(MAKECMDGOALS)))
  define infostring =

Build target '$(TARGET)' from *.cpp and *.cc sourcefiles

Sources found : $(sourcescpp) $(sourcescc)

Objects to build : $(objectscpp) $(objectscc)

All include (system) directories : $(INCSYSDIRS)

$(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(bmodeflags)

Compiler command : $(CXX)

Custom compiler options: $(CXXFLAGS)

Building with WARN_LEVEL=$(WARN_LEVEL) : $(cxxwarnings)

Warning level 1 includes : $(cxxwarn1)

Warning level 2 adds : $(cxxwarn2)

Warning level 3 adds : $(cxxwarn3)

The active warning include file is: $(MAKEFILE_WARN)

All generated dependecies: $(depfiles)

  endef
endif

production_goals = all build compdb
cleanup_goals = clean cleanall
action_goals = $(production_goals) $(cleanup_goals)
phony_goals = $(action_goals) info help

.SUFFIXES:        # deletes the old fashioned suffix rules from database (speedup)
.DELETE_ON_ERROR: # instructs make to delete the target of a rule if it has changed and its recipe
# exits with a nonzero status
.PHONY: $(phony_goals)
$(firstword $(action_goals)): # ensures that 'all' is the default (first target without a dot) goal

SHELL = /bin/bash
.SHELLFLAGS := -ec

# command definitions which are not in the default database
MV = mv -f

makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk
compile_database_name :=  compile_commands.json
last_config_store_name := .last_config_store
temp_config_store_name := .temp_config_store

single_make_options := $(firstword -$(MAKEFLAGS))
ifeq (s,$(findstring s,$(single_make_options)))
  silent_mode = 1
endif

# include project specific definitions if any
-include $(makefile_defs)

# add the defaults
WARN_LEVEL ?= 2
MAKEFILE_WARN ?= warnings.mk
BUILD_MODE ?= debug
COMP_FLAGS_RUN ?= -O2 -g1
ifeq (,$(findstring clang,$(CXX)))
  COMP_FLAGS_DEBUG ?= -Og -g3
else
  COMP_FLAGS_DEBUG ?= -Og -gline-tables-only
endif

# include warning definitions in file makefile_warn and complement default values
-include $(MAKEFILE_WARN)
cxxwarn0 ?= -ftabstop=4
cxxwarn1 ?= -pedantic -Wall -Wextra
cxxwarn2 ?= -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wmissing-declarations\
  -Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion\
  -Wsign-conversion -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant\
  -Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
cxxwarn3 ?= -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch\
  -Wunused-macros -Wstrict-overflow=5

ifeq ($(WARN_LEVEL),0)
  cxxwarnings := $(cxxwarn0)
else ifeq ($(WARN_LEVEL),1)
  cxxwarnings := $(cxxwarn1) $(cxxwarn0)
else ifeq ($(WARN_LEVEL),2)
  cxxwarnings := $(cxxwarn2) $(cxxwarn1) $(cxxwarn0)
else ifeq ($(WARN_LEVEL),3)
  cxxwarnings := $(cxxwarn3) $(cxxwarn2) $(cxxwarn1) $(cxxwarn0)
else
  $(error Invalid WARN_LEVEL=$(WARN_LEVEL))
endif

ifeq ($(BUILD_MODE),run)
  bmodeflags := $(COMP_FLAGS_RUN)
  modeinfostring := Building optimized release version
else ifeq ($(BUILD_MODE),debug)
  bmodeflags := $(COMP_FLAGS_DEBUG)
  modeinfostring := Building with debug information
else
  $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
endif

# get the last path component from the realpath of this filename as target name
TARGET ?= $(lastword $(subst /, ,$(dir $(realpath $(makefile_this)))))
# determines all sources, objects, dependecies, required flags
sourcescpp := $(wildcard *.cpp)
sourcescc := $(wildcard *.cc)
objectscpp := $(sourcescpp:.cpp=.o)
objectscc := $(sourcescc:.cc=.o)
depfiles := $(sourcescpp:.cpp=.d) $(sourcescc:.cc=.d)
dbfragmentscpp := $(addsuffix .jj.tmp,$(sourcescpp))
dbfragmentscc := $(addsuffix .jj.tmp,$(sourcescc))
incflags := $(addprefix -I,$(INCSYSDIRS))
allsources := $(sourcescpp) $(sourcescc)
alltargets := $(objectscpp) $(objectscc) $(TARGET)

# check goals
goals := $(MAKECMDGOALS)
ifeq (,$(goals))
  goals := all
endif
current_production_goals = $(filter $(production_goals),$(goals))
current_target_goals = $(filter $(alltargets),$(goals))
current_cleanup_goals = $(filter $(cleanup_goals),$(goals))
# option -j is in makeflags in word after the single character options
ifeq (-j,$(findstring -j,$(filter -j%, $(MFLAGS))))
  ifneq (,$(current_cleanup_goals))
    ifneq (,$(or $(current_production_goals),$(current_target_goals)))
      $(error Cleanup and production is not allowed with parallel make enabled!)
    endif
  endif
endif
ifeq (cleanall,$(findstring cleanall,$(goals)))
  $(intcmp $(words $(goals)),2,,$(error cleanall must be the only goal!))
endif

# call OUTPUT_OPTION,outfile
OUTPUT_OPTION = -o $(1)
# OUTPUT_OPTION and allxxxflags go into the compilation database, depflags don't
allflags = $(CXXFLAGS) $(bmodeflags) $(incflags) $(CPPFLAGS) $(cxxwarnings) -fmessage-length=0\
  $(TARGET_ARCH) -c
depflags = -MMD -MF$(@:%.o=%.d) -MP -MT$@


# prints info only if not silent (-s option) and not help goal or info goal
ifndef silent_mode
  ifeq (,$(or $(findstring help,$(MAKECMDGOALS)),$(findstring info,$(MAKECMDGOALS))))
    $(info )
      $(info Build target '$(TARGET)' from *.cpp and *.cc sourcefiles)
      $(info )
    $(info Sources found : $(allsources))
    $(info )
    $(info All include (system) directories : $(INCSYSDIRS))
    $(info )
  endif
endif

# call neq,param1,param2
# Expands to 'true' if param1 and param2 are not equal or to the empty string otherwise
neq = $(if $(subst $(2),,$(1)),true)

# call tail,separator,wordlist
# Expands to the rest of the word list that follows the separator word.
tail = $(let first rest,$(2),$(if $(and $(rest),$(call neq,$(1),$(first))),$(call tail,$(1),$(rest)),$(rest)))

# prepare configuration store
arg_vars = $(sort $(call tail,--,$(MAKEFLAGS)))

define configuration =
TARGET=$(value TARGET)
INCSYSDIRS=$(value INCSYSDIRS)
WARN_LEVEL=$(value WARN_LEVEL)
MAKEFILE_WARN=$(value MAKEFILE_WARN)
BUILD_MODE=$(value BUILD_MODE)
COMP_FLAGS_RUN=$(value COMP_FLAGS_RUN)
COMP_FLAGS_DEBUG=$(value COMP_FLAGS_DEBUG)
CPPFLAGS=$(value CPPFLAGS)
CXXFLAGS=$(value CXXFLAGS)
TARGET_ARCH=$(value TARGET_ARCH)
LDFLAGS=$(value LDFLAGS)
LDLIBS=$(value LDLIBS)
CXX=$(value CXX)
DISABLE_CONFIG_CHECK=$(value DISABLE_CONFIG_CHECK)
OUTPUT_OPTION=$(value OUTPUT_OPTION)
ARG_VARS=$(arg_vars)
cxxwarnings=$(strip $(cxxwarnings))
endef

ifdef DISABLE_CONFIG_CHECK
  last_config_store_target =
else
  last_config_store_target = $(last_config_store_name)
  # check for configuration changes only for production goals
  ifneq (,$(or $(current_production_goals),$(current_target_goals)))
    compare_configuration := $(file < $(last_config_store_name))
    prompt := No configuration change detected.
    ifneq ($(compare_configuration),$(configuration))
      # if configuration has changed: remove the configuration storage and store the temp_config_store
      prompt := Configuration has changed!
      $(shell $(RM) '$(last_config_store_name)')
      $(file > $(temp_config_store_name),$(configuration))
    endif
    ifndef silent_mode
      $(info $(prompt))
      $(info )
    endif
  endif
endif

# The new line variable requires 2 empty lines!
define new_line :=


endef
empty =
comma = ,
space = $(empty) $(empty)
# call conditional_echo,string
ifndef silent_mode
  conditional_echo = @echo -e "$(1)"
else
  conditional_echo =
endif
# depflags, output option and source are single quoted
compile_source = $(CXX) $(allflags) $(foreach var,$(depflags) $(call OUTPUT_OPTION,$@) $<,'$(var)')

# quote double quote
qdq = $(subst ",\\\",$(1))
# Function to produce one Compilation Database fragment
# call compdb_file_entry,sourcename,targetname
compdb_file_entry = {\n\
  $(space)\"directory\": \"$(call qdq,$(CURDIR))\",\n\
  $(space)\"file\": \"$(call qdq,$(1))\",\n\
  $(space)\"arguments\": [$(foreach var,$(CXX) $(allflags) $(call OUTPUT_OPTION,$(2)),\"$(call qdq,$(var))\"$(comma)) \"$(call qdq,$(1))\"],\n\
  $(space)\"output\": \"$(call qdq,$(2))\" }

# rules:
all: compdb build

compdb: $(compile_database_name)

$(compile_database_name): $(dbfragmentscpp) $(dbfragmentscc)
	@echo "[" > '$@'
	@sq=''; for x in $(foreach var,$^,'$(var)'); do \
	[[ -n $${sq} ]] && echo "," >> '$@'; cat "$$x" >> '$@'; sq=1; done
	@echo "]" >> '$@'
	$(call conditional_echo,Finished database $@\n)

$(dbfragmentscpp): $(makefile_this) $(last_config_store_target)
	@echo -e "$(call compdb_file_entry,$(@:%.jj.tmp=%),$(@:%.cpp.jj.tmp=%.o))" > '$@'
	$(call conditional_echo,Finished database fragment $@)

$(dbfragmentscc): $(makefile_this) $(last_config_store_target)
	@echo -e "$(call compdb_file_entry,$(@:%.jj.tmp=%),$(@:%.cc.jj.tmp=%.o))" > '$@'
	$(call conditional_echo,Finished database fragment $@)

.INTERMEDIATE: $(dbfragmentscpp) $(dbfragmentscc)

# when no configuration file exists, this rule and all depending rules are forced to run
ifndef DISABLE_CONFIG_CHECK
$(last_config_store_target):
	@$(MV) '$(temp_config_store_name)' '$@'
endif

build: $(TARGET)

$(TARGET): $(objectscpp) $(objectscc)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $(foreach var,$^,'$(var)') $(LDLIBS) -o '$@'
	$(call conditional_echo,Finished linking target: $@\n)

$(objectscpp): %.o: %.cpp $(makefile_this) $(last_config_store_target)
	$(compile_source)
	$(call conditional_echo,Finished building: $<\n)

$(objectscc): %.o: %.cc $(makefile_this) $(last_config_store_target)
	$(compile_source)
	$(call conditional_echo,Finished building: $<\n)

# includes additional rules after default rule
-include $(depfiles)

clean:
	$(call conditional_echo,Cleanup)
	-$(RM) $(foreach var,$(alltargets) $(depfiles),'$(var)')
	$(call conditional_echo,)

cleanall: clean
	$(call conditional_echo,Cleanup configuration store and compilation database)
	-$(RM) '$(last_config_store_name)' '$(temp_config_store_name)' '$(compile_database_name)'
	-$(RM) $(foreach var,$(dbfragmentscpp) $(dbfragmentscc),'$(var)')
	$(call conditional_echo,)

info:
	$(info $(infostring))
	@$(CXX) --version
	@echo

help:
	$(info $(helpstring))
