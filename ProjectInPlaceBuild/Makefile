# defines this help text string in the initial recursion level only
ifndef MAKE_IT_SIMPLE_PROJECT_IN_PLACE_BUILD_RECURSION
  define helpstring =
    This make script builds one executable from all %.cpp and %.cc source files in the current/project directory.

    Synopsis
        make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]
      or
        [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] make [make-options] [goal ...]

    Goals:
      all    Build the target executable - default goal.
      clean  Clean up the target executable and all build artefacts.
      info   Print project info.
      help   Print this help text.
      %.o    Build this object file if a coresponding source file exists.

    Files:
      Makefile        This make script
      $(makefile_defs)      This optional script contains the project customizations.
      $$(MAKEFILE_WARN) If the default warning options are not sufficient, this optional file can be used to define
                      specific warning options and will be included from Makefile.

    Optional customization variables:
      TARGET          Name of the executable to build. Default value is the last path component of this Makefile.
      INCSYSDIRS:     Space separated list of external include directories used with compiler option -I. Default: empty.
      WARN_LEVEL:     Warning level set 0 .. 3. Default: 2
      MAKEFILE_WARN:  The name of the file with specific warning options. Default: 'warnings.mk'
      BUILD_MODE:     Build mode set to 'run' or 'debug'. Default: 'debug'
      COMP_OPT_RUN:   Compiler optimization level and debug option with BUILD_MODE = run. Default: -O2 -g1 (clang: -Og -gline-tables-only)
      COMP_OPT_DEBUG: Compiler optimization level and debug option with BUILD_MODE = debug. Default: -Og -g3
      CPPFLAGS:       Extra compiler preprocessor options.
      CXXFLAGS:       Extra c++ compiler options (use for linker and compiler).
      TARGET_ARCH:    Target specific flags.
      LDFLAGS:        Extra linker options, such as -L.
      LDLIBS:         Extra library flags given to the linker.
      CXX             The compiler command to be used. Default: 'g++'

    Description:
      This make script builds one executable from all %.cpp and %.cc source files in the current project directory. The name of
      the executable is defined through variable TARGET and the default is the last component of the directory which contains
      this Makefile.

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
endif

# TODO: do we need this?
SHELL = /bin/bash
.SHELLFLAGS := -c

makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk

# deletes the old fashioned suffix rules from database (speedup)
.SUFFIXES:
# instructs make to delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:

.PHONY: all clean info help
# ensures that 'all' is the default (first target without a dot) goal
all:

# include optional project specific definitions
-include $(makefile_defs)
# and add the defaults for the unset variables
# get the last path component from the realpath of this filename as target name
TARGET ?= $(lastword $(subst /, ,$(dir $(realpath $(makefile_this)))))
WARN_LEVEL ?= 2
MAKEFILE_WARN ?= warnings.mk
BUILD_MODE ?= debug
COMP_OPT_RUN ?= -O2 -g1
ifeq (,$(findstring clang,$(CXX)))
  COMP_OPT_DEBUG ?= -Og -g3
else
  COMP_OPT_DEBUG ?= -Og -gline-tables-only
endif

# The following initialization block is active in the initial recursion level only.
ifndef MAKE_IT_SIMPLE_PROJECT_IN_PLACE_BUILD_RECURSION
  export MAKE_IT_SIMPLE_PROJECT_IN_PLACE_BUILD_RECURSION = 1

  # Since the parallel execution is deactivated in the initial recursion level,
  # the execution of the command line goals is ensured in the intended order.
  .NOTPARALLEL:

  # include warning definitions in file makefile_warn and complement default values
  -include $(MAKEFILE_WARN)
  cxxwarn0 ?= -ftabstop=4
  cxxwarn1 ?= -pedantic -Wall -Wextra
  cxxwarn2 ?= -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wmissing-declarations \
-Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion \
-Wsign-conversion -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant \
-Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
  cxxwarn3 ?= -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros -Wstrict-overflow=5

  ifeq ($(WARN_LEVEL),0)
    export CXXWARNINGS := $(cxxwarn0)
  else ifeq ($(WARN_LEVEL),1)
    export CXXWARNINGS := $(cxxwarn1) $(cxxwarn0)
  else ifeq ($(WARN_LEVEL),2)
    export CXXWARNINGS := $(cxxwarn2) $(cxxwarn1) $(cxxwarn0)
  else ifeq ($(WARN_LEVEL),3)
    export CXXWARNINGS := $(cxxwarn3) $(cxxwarn2) $(cxxwarn1) $(cxxwarn0)
  else
    $(error Invalid WARN_LEVEL=$(WARN_LEVEL))
  endif

  ifeq ($(BUILD_MODE),run)
    export CXXOPT := $(COMP_OPT_RUN)
    modeinfostring := Building optimized release version
  else ifeq ($(BUILD_MODE),debug)
    export CXXOPT := $(COMP_OPT_DEBUG)
    modeinfostring := Building with debug information
  else
    $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
  endif

  # determines all sources, objects, dependecies, required flags and exports values for recursion
  export CPPSOURCES := $(wildcard *.cpp)
  export CCSOURCES := $(wildcard *.cc)
  export OBJECTSCPP := $(CPPSOURCES:.cpp=.o)
  export OBJECTSCC := $(CCSOURCES:.cc=.o)
  export DEPS := $(CPPSOURCES:.cpp=.d) $(CCSOURCES:.cc=.d)
  export INC_FLAGS := $(addprefix -I,$(INCSYSDIRS))

  # prints info only if not silent (-s option) and not help goal or info goal
  ifeq (,$(findstring s,$(MAKEFLAGS)))
    ifeq (,$(or $(findstring help,$(MAKECMDGOALS)),$(findstring info,$(MAKECMDGOALS))))
      $(info )
      $(info Build target '$(TARGET)' from *.cpp and *.cc sourcefiles)
      $(info )
      $(info Sources found : $(CPPSOURCES) $(CCSOURCES))
      $(info )
      $(info All include (system) directories : $(INCSYSDIRS))
      $(info )
    endif
  endif
endif

my_cxxflags := -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS)
# With recursive variables the automatic variables are expanded during receipt execution.
my_cppflags = -MMD -MF"$(@:%.o=%.d)" -MP -MT"$@" $(INC_FLAGS)

# rules:
all:
	@$(MAKE) -f $(makefile_this) $(TARGET)

$(TARGET): $(OBJECTSCPP) $(OBJECTSCC)
	$(CXX) $(my_cxxflags) $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LDLIBS) -o "$@"
	@echo -e 'Finished linking target: $@\n'

$(OBJECTSCPP): %.o: %.cpp $(makefile_this)
	$(CXX) $(my_cxxflags) $(CXXFLAGS) $(my_cppflags) $(CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

$(OBJECTSCC): %.o: %.cc $(makefile_this)
	$(CXX) $(my_cxxflags) $(CXXFLAGS) $(my_cppflags) $(CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

# includes additional rules after default rule
-include $(DEPS)

clean:
	@echo 'Cleanup'
	-$(RM) $(TARGET) *.o *.d
	-@echo

info:
	$(info )
	$(info Build target '$(TARGET)' from *.cpp and *.cc sourcefiles)
	$(info )
	$(info Sources found : $(CPPSOURCES) $(CCSOURCES))
	$(info )
	$(info Objects to build : $(OBJECTSCPP) $(OBJECTSCC))
	$(info )
	$(info All include (system) directories : $(INCSYSDIRS))
	$(info )
	$(info $(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(CXXOPT))
	$(info )
	$(info Compiler command : $(CXX))
	$(info )
	$(info Custom compiler options: $(CXXFLAGS))
	$(info )
	$(info Building with WARN_LEVEL=$(WARN_LEVEL) : $(CXXWARNINGS))
	$(info )
	$(info Warning level 1 includes : $(cxxwarn1))
	$(info )
	$(info Warning level 2 adds : $(cxxwarn2))
	$(info )
	$(info Warning level 3 adds : $(cxxwarn3))
	$(info )
	$(info The active warning include file is: $(MAKEFILE_WARN))
	$(info )
	$(info All generated dependecies: $(DEPS))
	$(info )
	@$(CXX) --version
	@echo -e '*********************************************\n'

help:
	$(info )
	$(info $(helpstring))
	$(info )
