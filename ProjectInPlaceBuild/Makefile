define helpstring =
  Build one executable $(target) from all %.cpp source files in a project directory.

    make [makeoptions] [BUILD_MODE=debug|run] [goal ...]

  Goals:
    all    Build the target executable - default target.
    clean  Clean all previousely build executables.
    help   Print this help text.
    %.o    Build this object file if a coresponding %.cpp exists.

  useful makeoptions:
    -h, --help          Display help.
    -j [N], --jobs[=N]  Allow N jobs at once; infinite jobs with no arg.
    -B, --always-make   Unconditionally make all targets.

  The executable is build with debug information included.
  With variable
    BUILD_MODE=run
  an optimized executable without debug information is built.
  The default warning level is '-Wall'. Variable 'CXXWARNINGS' changes the warning level.
  More copiler options can be given with variables CXXFLAGS, CPPFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS
endef

target := program
cppsources := $(wildcard *.cpp)
objects := $(cppsources:.cpp=.o)
deps := $(cppsources:.cpp=.d)

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
ALL_CXXFLAGS = -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS) $(CXXFLAGS)
ALL_CPPFLAGS = -MMD -MF"$(@:%.o=%.d)" -MP -MT"$@" $(CPPFLAGS)

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help echoobjects

all: $(target)

clean:
	@echo 'Cleanup'
	-$(RM) $(target) *.o *.d
	-@echo ' '

help:
	$(info $(helpstring))
	@echo

echoobjects:
	$(info Detected objects: $(objects))
	$(info )

$(target): $(objects)
	@echo 'Linking target: $@'
	$(CXX) $(ALL_CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o "$@"
	@echo 'Finished linking target: $@'
	@echo ' '

%.o: %.cpp | echoobjects
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(ALL_CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

# include additional rules after default rule!
-include $(deps)
