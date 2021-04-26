define helpstring :=
  Build executables from each found %.cpp source file.

    make [makeoptions] [BUILD_MODE=debug|run] [goal ...]

  Goals:
    all    Build an executable with every *.cpp file in the current directory - default target.
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
  More copiler options can be given with variables CXXFLAGS, CPPFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS
endef

cppsources = $(wildcard *.cpp)
targets = $(cppsources:.cpp=)

BUILD_MODE ?= debug
ifeq ($(BUILD_MODE),run)
  CXXOPT := -O3
  infostring := Building optimized release version $(CXXOPT)
else ifeq ($(BUILD_MODE),debug)
  CXXOPT := -O0 -g3
  infostring := Building with debug information $(CXXOPT)
else
  $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
endif

noprint := $(or $(findstring clean,$(MAKECMDGOALS)),$(findstring help,$(MAKECMDGOALS)))
ifndef noprint
  $(info $(infostring))
endif
$(info )

CXXWARNINGS ?= -Wall
ALL_CXXFLAGS = -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS) $(CPPFLAGS)

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help echo_targets

all: $(targets)

clean: | echotargets
	@echo 'Cleanup'
	-$(RM) $(targets)
	-@echo ' '

help:
	$(info $(helpstring))
	@echo

echotargets:
	$(info Potential targets detected : $(targets))
	$(info )

%: %.cpp | echotargets
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH) -o "$@" $(LOADLIBES) $(LDLIBS) "$<"
	@echo 'Finished building: $<'
	@echo ' '
