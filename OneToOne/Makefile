SHELL = /bin/bash

makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk
makefile_warn := warnings.mk

# delete the old fashioned suffix rules from database
.SUFFIXES:
# instruct make to delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:
.PHONY: all clean help recursion_goal
# ensure that 'all' is the default goal (first target without a dot)
all:

# include project specific definitions if any
-include $(makefile_defs)

# initialization block of the initial recursion level
ifndef MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION
  export MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION = 1

  # parallel execution is disabled in the first level invocation
  .NOTPARALLEL:

  define helpstring =
    This make script builds executables from each %.cpp source file found in the current directory.

    Synopsis
        make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]
      or
        [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] make [make-options] [goal ...]

    Goals:
      all    Build an executable with every *.cpp file in the current directory - default goal.
      clean  Clean up all generated executables.
      help   Print this help text.
      %      Build this target file if a coresponding %.cpp exists.

    Files:
      Makefile        This make script
      $(makefile_warn)     If the default warning options are not sufficient, this optional file can be used to define
                      specific warning options and will be included from Makefile.
      $(makefile_defs)      This optional file may contains project specific customizations.

    Optional customization variables:
      BUILD_MODE:   Build mode set to 'run' or 'debug'.
      WARN_LEVEL:   Warning level set 0 .. 3.
      INCLUDE_DIRS: Space separated list of external include directories (-I).
      CPPFLAGS:     Extra compiler preprocessor options.
      CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
      TARGET_ARCH   Target specific flags.
      LDFLAGS:      Extra linker options, SUCH AS -L.
      LDLIBS:       Extra library flags given to the linker.

    Description:
      This make script builds executables from each %.cpp source file found in the current directory.
      If variable BUILD_MODE is not set or has the value debug, the executables are build with debug information included.
      If variable BUILD_MODE=run optimized executables without debug information are built.

      The variable WARN_LEVEL can assign warning levels from 0 .. 3.
      The default warning level is 2 and activates a comprehensive set of warnings (for gcc).
      More compiler options can be given with variables INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS

      If parallel execution is requested, the script executes the command line goals in the designated order and switches 
      for goal 'all' to parallel execution mode in recursion level 1.

    Some useful make-options:
      -h, --help                      Display help.
      -j [N], --jobs[=N]              Allow N jobs at once; infinite jobs with no arg.
      -k, --keep-going                Continue as much as possible after an error.
      -B, --always-make               Unconditionally make all targets.
      -s, --silent, --quiet           Don't echo recipes.
      -O[TYPE], --output-sync[=TYPE]  Synchronize output of parallel jobs by TYPE (none|line|target|recurse).

    Compiler flags warning level 1 includes:
      $(cxxwarn1)

    Warning levels 2 additionally includes:
      $(cxxwarn2)

    Warning levels 3 additionally includes:
      $(cxxwarn3)
  endef

  # determine all required objects
  export CPPSOURCES := $(wildcard *.cpp)
  export TARGETS := $(CPPSOURCES:.cpp=)
  export DEPS := $(CPPSOURCES:.cpp=.d)

  export INC_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))

  # the defaul warnings are:
  cxxwarn0 = -ftabstop=4
  cxxwarn1 = -pedantic -Wall -Wextra
  cxxwarn2 = -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wmissing-declarations \
  -Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion \
  -Wsign-conversion -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant \
  -Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
  cxxwarn3 = -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros -Wstrict-overflow=5
  # overwrite warning definitions if defaults are not sufficient
  -include $(makefile_warn)

  WARN_LEVEL ?= 2
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

  BUILD_MODE ?= debug
  ifeq ($(BUILD_MODE),run)
    cxxopt := -O3
    infostring := Building optimized release version $(cxxopt)
  else ifeq ($(BUILD_MODE),debug)
    cxxopt := -O0 -g3
    infostring := Building with debug information $(cxxopt)
  else
    $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
  endif

  # print info only if not silent and not help goal
  ifeq (,$(findstring s,$(MAKEFLAGS)))
    ifneq ($(MAKECMDGOALS),help)
      $(info )
      $(info Detected targets : $(TARGETS))
      $(info $(infostring))
      $(info )
      $(info  Building with WARN_LEVEL=$(WARN_LEVEL) included flags:)
      $(info $(cxxwarnings))
      $(info )
    endif
  endif

  export ALL_CXXFLAGS := -fmessage-length=0 $(cxxopt) $(cxxwarnings) $(CXXFLAGS)

endif

# With recursive variables the automatic variables may be expanded during receipt execution.
all_cppflags = -MMD -MP $(CPPFLAGS) $(INC_FLAGS)

all:
	@$(MAKE) -f $(makefile_this) recursion_goal

recursion_goal: $(TARGETS)

clean:
	@echo 'Cleanup'
	-$(RM) $(TARGETS) *.d
	-@echo

help:
	$(info )
	$(info $(helpstring))
	$(info )

$(TARGETS): %: %.cpp $(makefile_this)
	$(CXX) $(ALL_CXXFLAGS) $(all_cppflags) $(LDFLAGS) $(TARGET_ARCH) -o "$@" $(LOADLIBES) $(LDLIBS) "$<"
	@echo -e 'Finished building: $<\n'

# include additional rules after default rule!
-include $(DEPS)
