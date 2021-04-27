define HELPSTRING :=
  Build executables from each found %.cpp source file.

    make [makeoptions] [BUILD_MODE=debug|run] [goal ...]

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
  The default warning level is '-Wall'. Variable 'CXXWARNINGS' changes the warning level.
  More copiler options can be given with variables CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS

  Variables:
    BUILD_MODE:   Build mode set to 'run' or 'debug'.
    CPPFLAGS:     Extra compiler preprocessor options.
    CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
    LDFLAGS:      Extra linker options, SUCH AS -L.
    LDLIBS:       Extra library flags given to the linker.
endef

CXXWARNINGS ?= -Wall

CPPSOURCES = $(wildcard *.cpp)
TARGETS = $(CPPSOURCES:.cpp=)

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

NOPRINT := $(or $(findstring clean,$(MAKECMDGOALS)),$(findstring help,$(MAKECMDGOALS)))
ifndef NOPRINT
  $(info $(INFOSTRING))
endif
$(info )

ALL_CXXFLAGS = -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS) $(CXXFLAGS)

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help echotargets

all: $(TARGETS)

clean: | echotargets
	@echo 'Cleanup'
	-$(RM) $(TARGETS)
	-@echo ' '

help:
	$(info $(HELPSTRING))
	@echo

echotargets:
	$(info Potential targets detected : $(TARGETS))
	$(info )

%: %.cpp | echotargets
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH) -o "$@" $(LOADLIBES) $(LDLIBS) "$<"
	@echo 'Finished building: $<'
	@echo ' '
