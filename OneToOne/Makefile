ifndef MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION
  define HELPSTRING =
    Build executables from each found %.cpp source file.

      make [makeoptions] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]

    Goals:
      all    Build an executable with every *.cpp file in the current directory - default goal.
      clean  Clean all previousely build executables.
      help   Print this help text.
      %      Build this target file if a coresponding %.cpp exists.

    useful makeoptions:
      -h, --help          Display help.
      -j [N], --jobs[=N]  Allow N jobs at once; infinite jobs with no arg.
      -B, --always-make   Unconditionally make all targets.

    The executables are build with debug information included.
    With variable
      BUILD_MODE=run
    optimized executables without debug information are built.
    The variable WARN_LEVEL can assign warning levels from 0 .. 3.
    The default warning level is 2 and activates a comprehensive set of warnings (for gcc).
    More copiler options can be given with variables CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS

    Variables:
      BUILD_MODE:   Build mode set to 'run' or 'debug'.
      WARN_LEVEL:   Warning level set 0 .. 3.
      CPPFLAGS:     Extra compiler preprocessor options.
      CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
      LDFLAGS:      Extra linker options, SUCH AS -L.
      LDLIBS:       Extra library flags given to the linker.

    Compiler flags warning level 1 includes:
      $(CXXWARN1)

    Warning levels 2 additionally includes:
      $(CXXWARN2)

    Warning levels 3 additionally includes:
      $(CXXWARN3)
  endef

  # determine all required objects
  export CPPSOURCES := $(wildcard *.cpp)
  export TARGETS := $(CPPSOURCES:.cpp=)

  CXXWARN0 := -ftabstop=4
  CXXWARN1 := -pedantic -Wall -Wextra
  CXXWARN2 := -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wlogical-op -Wmissing-declarations \
  -Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion \
  -Wsign-conversion -Wstrict-null-sentinel -Wstrict-overflow=5 -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant \
  -Wuseless-cast -Wstrict-overflow=4 -Wattribute-alias -Wduplicated-branches -Wduplicated-cond -Wdate-time -Wextra-semi \
  -Wnull-dereference -Wno-aggressive-loop-optimizations -Wdisabled-optimization
  CXXWARN3 := -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros

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
  THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

.NOTPARALLEL:
endif

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help recursion

all:
	@$(MAKE) MAKE_IT_SIMPLE_ONE_TO_ONE_RECURSION=1 -f $(THIS_MAKEFILE) recursion

recursion: $(TARGETS)

clean:
	@echo 'Cleanup'
	-$(RM) $(TARGETS)
	-@echo ' '

help:
	$(info )
	$(info $(HELPSTRING))
	$(info )

%: %.cpp
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH) -o "$@" $(LOADLIBES) $(LDLIBS) "$<"
	@echo 'Finished building: $<'
	@echo ' '
