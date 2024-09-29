# defines this help text string in the initial recursion level only
ifndef MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION
  # Prepare the help string if required
  ifneq (,$(findstring help,$(MAKECMDGOALS)))
    define helpstring =

This make script builds executables from each %.cpp and %.cc source file found in the current directory
and maintains a JSON Compilation Database ($(compile_database_name)) for the clang language server.
The script supports 2 Build Modes (run and debug) and 4 Warning levels.
The Compilation Database is automatically updated when the configuration has changed.

Synopsis
    make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]
  or
    [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] make [make-options] [goal ...]
Goals:
  all       Build an executable with every *.cpp/*.cc file in the current directory - default goal.
  clean     Clean up all generated executables.
  clean_all Clean up all generated executables and the Compilation Database.
  info      Print project info.
  help      Print this help text.
  %         Build this target file if a coresponding sorce file exists.

Files:
  Makefile        This make script
  $(makefile_defs)      This optional script contains the project customizations.
  $$(MAKEFILE_WARN) If the default warning options are not sufficient, this optional file can be used to define
                    specific warning options and will be included from Makefile.

Optional customization variables:
  INCSYSDIRS:         Space separated list of external include directories used with compiler option -I. Default: empty.
  WARN_LEVEL:         Warning level set 0 .. 3. Default: 2
  MAKEFILE_WARN:      The name of the file with specific warning options. Default: 'warnings.mk'
  BUILD_MODE:         Build mode set to 'run' or 'debug'. Default: 'debug'
  COMP_FLAGS_RUN:     Compiler optimization level and debug option with BUILD_MODE = run. Default: -O2 -g1 (clang: -Og -gline-tables-only)
  COMP_FLAGS_DEBUG:   Compiler optimization level and debug option with BUILD_MODE = debug. Default: -Og -g3
  CPPFLAGS:           Extra compiler preprocessor options.
  CXXFLAGS:           Extra c++ compiler options (use for linker and compiler).
  TARGET_ARCH:        Target specific flags.
  LDFLAGS:            Extra linker options, such as -L.
  LDLIBS:             Space separated list of libraries given to the linker.
  CXX                 The compiler command to be used. Default: 'g++'
  DISABLE_COMPILE_DB: If set to anything other than the empty string, the Compilation Database generation is disabled.

Description:
  This make script builds executables from each %.cpp and %.cc source file found in the current directory.

  The Compilation Database is updated in allmost all goals if variable DISABLE_COMPILE_DB is unset. The only
  exception to this rule is if the target 'clean_all' is the last or only command-line target.

  If variable BUILD_MODE is not set or has the value debug, the executables are build with debug information included.
  If variable BUILD_MODE equals 'run', optimized executables without debug information are built.

  The variable WARN_LEVEL can assign warning levels from 0 .. 3.
  The default warning level is 2 and activates a comprehensive set of warnings (for gcc and clang).

  By default the g++ compiler is used. To use a different compiler, set variable CXX. E.g 'CXX=clang++'

  Use the CXXFLAGS variable to change the c++ language standard. E.g. 'CXXFLAGS=-std=c++11'.

  If parallel execution is requested, the script executes the command line goals in the designated order and switches
  for goal 'all' to parallel execution mode in recursion level 1.

Some useful make-options:
  -h, --help                      Display help.
  -j [N], --jobs[=N]              Allow N jobs at once; infinite jobs with no arg.
  -k, --keep-going                Continue as much as possible after an error.
  -B, --always-make               Unconditionally make all targets.
  -r, --no-builtin-rules          Disable the built-in implicit rules.
  -s, --silent, --quiet           Don't echo recipes.
  -O[TYPE], --output-sync[=TYPE]  Synchronize output of parallel jobs by TYPE (none|line|target|recurse).

    endef
    export helpstring
  endif
  # Prepare the info string if required
  ifneq (,$(findstring info,$(MAKECMDGOALS)))
    define infostring =

Sources found : $(CPPSOURCES) $(CCSOURCES)

Targets to build : $(TARGETSCPP) $(TARGETSCC)

All include (system) directories : $(INCSYSDIRS)

$(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(bmodeflags)

Compiler command : $(CXX)

Custom compiler options: $(CXXFLAGS)

Building with WARN_LEVEL=$(WARN_LEVEL) : $(cxxwarnings)

Warning level 1 includes : $(cxxwarn1)

Warning level 2 adds : $(cxxwarn2)

Warning level 3 adds : $(cxxwarn3)

The active warning include file is: $(MAKEFILE_WARN)

All generated dependecies: $(DEPS)
    endef
    export infostring
  endif
endif

# Common initialization for both recursion levels
SHELL = /bin/bash
.SHELLFLAGS := -c

.POSIX:
# deletes the old fashioned suffix rules from database (speedup)
.SUFFIXES:
# instructs make to delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:

.PHONY: all clean clean_all info help recursion_goal
# ensures that 'all' is the default (first target without a dot) goal
all:

makefile_this := $(lastword $(MAKEFILE_LIST))

compile_database_name := compile_commands.json
ifndef DISABLE_COMPILE_DB
  compile_database_target := $(compile_database_name)
endif

ifeq (s,$(findstring s,$(firstword $(MAKEFLAGS))))
  silent_mode = 1
endif
# The new line variable requires 2 empty lines!
define new_line :=


endef

# include project specific definitions if any
makefile_defs := project.mk
-include $(makefile_defs)

# The following initialization block is active in the initial recursion level only.
ifndef MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION
  export MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION = 1

  # Since the parallel execution is deactivated in the initial recursion level,
  # the execution of the command line goals is ensured in the intended order.
  .NOTPARALLEL:

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
  cxxwarn3 ?= -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros -Wstrict-overflow=5

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

  # determines all sources, objects, required flags and exports values for recursion
  export CPPSOURCES := $(wildcard *.cpp)
  export CCSOURCES := $(wildcard *.cc)
  export TARGETSCPP := $(CPPSOURCES:.cpp=)
  export TARGETSCC := $(CCSOURCES:.cc=)
  export DEPS := $(CPPSOURCES:.cpp=.d) $(CCSOURCES:.cc=.d)
  incflags := $(addprefix -I,$(INCSYSDIRS))
  libflags := $(addprefix -l,$(LDLIBS))
  all_sources := $(CPPSOURCES) $(CCSOURCES)

  # prints info only if not silent (-s option) and not help goal or info goal
  ifndef silent_mode
    ifeq (,$(or $(findstring help,$(MAKECMDGOALS)),$(findstring info,$(MAKECMDGOALS))))
      $(info )
      $(info Sources found : $(all_sources))
      $(info )
      $(info All include (system) directories : $(INCSYSDIRS))
      $(info )
    endif
  endif

  export ALLSTATFLAGS := $(CXXFLAGS) $(bmodeflags) $(incflags) $(CPPFLAGS) $(cxxwarnings) -fmessage-length=0 $(LDFLAGS) $(libflags) $(TARGET_ARCH)

  # compiler database functions
  #make the compile database option for clang: -MJ$@.jj
  actiongoals = $(filter-out help info,$(MAKECMDGOALS))
  ifeq (clean_all,$(lastword $(actiongoals)))
    finally_delete_database = 1
  else
    ifndef DISABLE_COMPILE_DB
      source_list_tail := $(lastword $(all_sources))
      source_list_head := $(filter-out $(source_list_tail),$(all_sources))

      # call file_entry,sourcename
      define file_entry =
 {
    "directory": "$(PWD)",
    "arguments": [$(foreach var,$(subst ",\",$(CXX) $(ALLSTATFLAGS)),"$(var)",) "-o", "$(1)", "$(basename $(1))"],
    "file": "$(1)",
    "output": "$(basename $(1))"
  }
      endef

      compile_database := [$(new_line)\
        $(foreach var,$(source_list_head), $(call file_entry,$(var)),$(new_line))\
        $(call file_entry,$(source_list_tail))$(new_line)]

      compare_database := $(file < $(compile_database_name))
      prompt := Compile Database is up to date.
      ifneq ($(compare_database),$(compile_database))
        prompt := Write Compile Database!
        $(file > $(compile_database_name),$(compile_database))
      endif
      # prints info only if not silent (-s option)
      ifndef silent_mode
        $(info $(prompt))
        $(info )
      endif
    endif
  endif
endif # ifndef MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION

# Define the recursive variable in the actual recursion level!
# The export seems to be done during recursion invocation.
DEPFLAGS = -MMD '-MF$(@:%=%.d)' -MP '-MT$@'
OUTPUT_OPTION = -o '$@'
define conditional_echo =
ifndef silent_mode
echo "$(1)"
endif
endef
define compile_source =
$(CXX) $(ALLSTATFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) '$<'
endef
ifndef silent_mode
  compile_source += $(new_line)
  compile_source += @echo -e 'Finished building: $<\n'
endif

# rules:
all:
	@$(MAKE) -f $(makefile_this) recursion_goal

recursion_goal: $(TARGETSCPP) $(TARGETSCC)

$(TARGETSCPP): %: %.cpp $(makefile_this) $(compile_database_target)
	$(compile_source)

$(TARGETSCC): %: %.cc $(makefile_this) $(compile_database_target)
	$(compile_source)

# includes additional rules after default rule
-include $(DEPS)

clean:
ifndef silent_mode
	@echo 'Cleanup'
endif
	-$(RM) $(foreach var,$(TARGETSCPP) $(TARGETSCC) $(DEPS),'$(var)')
ifndef silent_mode
	-@echo
endif

clean_all: clean
ifdef finally_delete_database
	-$(RM) '$(compile_database_name)'
  ifndef silent_mode
	-@echo
  endif
endif

info:
	@echo "$${infostring}"
	@$(CXX) --version
	@echo

help:
	@echo "$${helpstring}"
