define HELPSTRING =
  Build one executable $(BINDIR)/$(TARGET) from all %.cpp source files in a project source directories.

    make [makeoptions] [BUILD_MODE=debug|run] [more variables] [goal ...]

  Goals:
    all    Build the target executable - default target.
    clean  Clean all previousely build executables.
    help   Print this help text.

  useful makeoptions:
    -h, --help          Display help.
    -j [N], --jobs[=N]  Allow N jobs at once; infinite jobs with no arg.
    -B, --always-make   Unconditionally make all targets.

  The executable is build with debug information included.
  With variable
    BUILD_MODE=run
  an optimized executable without debug information is built.
  The default warning level is '-Wall'. Variable 'CXXWARNINGS' changes the warning level.
  More copiler options can be given with variables INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS.

  Variables:
    BUILD_MODE:   Build mode set to 'run' or 'debug'.
    INCLUDE_DIRS: Space separated list of external include directories (-I).
    CPPFLAGS:     Extra compiler preprocessor options.
    CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
    LDFLAGS:      Extra linker options, SUCH AS -L.
    LDLIBS:       Extra library flags given to the linker.
endef

# Project specific settings
TARGET := program
SRCDIRS := . src
INCDIRS := include
BUILDDIR := build
BINDIR := bin
CXXWARNINGS ?= -Wall

# search source files and make dependent variables
BUILDDIRS = $(addprefix $(BUILDDIR)/,$(SRCDIRS))
CPPSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cpp))
OBJECTS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.o))
DEPS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.d))

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

INC_FLAGS := $(addprefix -I,$(INCDIRS)) $(addprefix -I,$(INCLUDE_DIRS))
ALL_CXXFLAGS = -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS) $(CXXFLAGS)
ALL_CPPFLAGS = -MMD -MF"$(@:%.o=%.d)" -MP -MT"$@" $(CPPFLAGS) $(INC_FLAGS)

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help echoinfo

all: $(BINDIR)/$(TARGET)

clean:
	@echo 'Cleanup'
	-$(RM) $(BINDIR)/$(TARGET)
	-$(RM) -r $(BUILDDIR)
	-@echo

help:
	$(info $(HELPSTRING))
	@echo

echoinfo:
	$(info Build directories: $(BUILDDIRS))
	$(info Detected objects: $(OBJECTS))
	$(info )

$(BUILDDIRS):
	mkdir -p '$@'

$(BINDIR):
	mkdir -p '$@'

$(BINDIR)/$(TARGET): $(OBJECTS) | $(BINDIR)
	@echo 'Linking target: $@'
	$(CXX) $(ALL_CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o "$@"
	@echo -e 'Finished linking target: $@\n'

$(BUILDDIR)/%.o: %.cpp | echoinfo $(BUILDDIRS)
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(ALL_CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

# include additional rules after default rule!
-include $(DEPS)
