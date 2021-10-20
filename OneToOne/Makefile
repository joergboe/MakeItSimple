SHELL = /bin/bash

MAKEFILE_THIS := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DEFS := definitions.mk
MAKEFILE_WARN := warnings.mk

# include project specific definitions if any
-include $(MAKEFILE_DEFS)

ifndef MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION
  define HELPSTRING =
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
      $(MAKEFILE_WARN)     If the default warning options are not sufficient, this optional file can be used to define
                      specific warning options and will be included from Makefile.
      $(MAKEFILE_DEFS)  Define further project definitions and options in this file if required.

    Some useful make-options:
      -h, --help                      Display help.
      -j [N], --jobs[=N]              Allow N jobs at once; infinite jobs with no arg.
      -k, --keep-going                Continue as much as possible after an error.
      -B, --always-make               Unconditionally make all targets.
      -s, --silent, --quiet           Don't echo recipes.
      -O[TYPE], --output-sync[=TYPE]  Synchronize output of parallel jobs by TYPE (none|line|target|recurse).

    Variables:
      BUILD_MODE:   Build mode set to 'run' or 'debug'.
      WARN_LEVEL:   Warning level set 0 .. 3.
      INCLUDE_DIRS: Space separated list of external include directories (-I).
      CPPFLAGS:     Extra compiler preprocessor options.
      CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
      LDFLAGS:      Extra linker options, SUCH AS -L.
      LDLIBS:       Extra library flags given to the linker.

    Description:
      This make script builds executables from each %.cpp source file found in the current directory.
      If variable BUILD_MODE is not set or has the value debug, the executables are build with debug information included.
      If variable BUILD_MODE=run optimized executables without debug information are built.

      The variable WARN_LEVEL can assign warning levels from 0 .. 3.
      The default warning level is 2 and activates a comprehensive set of warnings (for gcc).
      More compiler options can be given with variables INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS

      This script ensures that the first level goals (clean, all) are executed in the designated order
      if the script is invoked for parallel execution (make options --jobs or --load-average)

    Compiler flags warning level 1 includes:
      $(CXXWARN1)

    Warning levels 2 additionally includes:
      $(CXXWARN2)

    Warning levels 3 additionally includes:
      $(CXXWARN3)
  endef

  # include warning definitions if defaults are not sufficient
  -include $(MAKEFILE_WARN)

  # determine all required objects
  export CPPSOURCES := $(wildcard *.cpp)
  export TARGETS := $(CPPSOURCES:.cpp=)

  export INC_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))

  CXXWARN0 ?= -ftabstop=4
  CXXWARN1 ?= -pedantic -Wall -Wextra
  CXXWARN2 ?= -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wmissing-declarations \
  -Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion \
  -Wsign-conversion -Wstrict-overflow=5 -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant \
  -Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
  CXXWARN3 ?= -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros

  WARN_LEVEL ?= 2
  ifeq ($(WARN_LEVEL),0)
    CXXWARNINGS := $(CXXWARN0)
  else ifeq ($(WARN_LEVEL),1)
    CXXWARNINGS := $(CXXWARN1) $(CXXWARN0)
  else ifeq ($(WARN_LEVEL),2)
    CXXWARNINGS := $(CXXWARN2) $(CXXWARN1) $(CXXWARN0)
  else ifeq ($(WARN_LEVEL),3)
    CXXWARNINGS := $(CXXWARN3) $(CXXWARN2) $(CXXWARN1) $(CXXWARN0)
  else
    $(error Invalid WARN_LEVEL=$(WARN_LEVEL))
  endif

  BUILD_MODE ?= debug
  ifeq ($(BUILD_MODE),run)
    CXXOPT := -O3
    INFOSTRING := Building optimized release version $(CXXOPT)
  else ifeq ($(BUILD_MODE),debug)
    CXXOPT := -O0 -g3
    INFOSTRING := Building with debug information $(CXXOPT)
  else
    $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
  endif

  ifneq ($(MAKECMDGOALS),help)
    $(info )
    $(info Detected targets : $(TARGETS))
    $(info $(INFOSTRING))
    $(info )
    $(info  Building with WARN_LEVEL=$(WARN_LEVEL) included flags:)
    $(info $(CXXWARNINGS))
    $(info )
  endif

  export ALL_CXXFLAGS := -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS) $(CXXFLAGS)

.NOTPARALLEL:
endif

# cpp-flags require recursive variable flavor in some other makefile variants
ALL_CPPFLAGS = $(CPPFLAGS) $(INC_FLAGS)

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help all_targets

all:
	@$(MAKE) MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION=1 -f $(MAKEFILE_THIS) all_targets

all_targets: $(TARGETS)

clean:
	@echo 'Cleanup'
	-$(RM) $(TARGETS)
	-@echo

help:
	$(info )
	$(info $(HELPSTRING))
	$(info )

$(TARGETS): %: %.cpp $(MAKEFILE_THIS)
	$(CXX) $(ALL_CXXFLAGS) $(ALL_CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH) -o "$@" $(LOADLIBES) $(LDLIBS) "$<"
	@echo -e 'Finished building: $<\n'
