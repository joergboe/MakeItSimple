define HELPSTRING =
  Build one executable $(TARGET) from all %.cpp source files in a project source directories.

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

TARGET := program
SRCDIRS := . src
INCDIRS := include
BUILDDIR := build
BINDIR := bin

BUILDDIRS = $(addprefix $(BUILDDIR)/,$(SRCDIRS))
$(info $(BUILDDIRS))

CPPSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cpp))
OBJS := $(CPPSOURCES:.cpp=.o)
$(info $(OBJS))
OBJECTS := $(addprefix $(BUILDDIR)/,$(OBJS))
$(info $(OBJECTS))

DEP := $(CPPSOURCES:.cpp=.d)
DEPS := $(addprefix $(BUILDDIR)/,$(DEP))
$(info $(DEPS))

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

CXXWARNINGS ?= -Wall
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
	-@echo ' '

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
	@echo 'Finished linking target: $@'
	@echo ' '

$(BUILDDIR)/%.o: %.cpp | echoinfo $(BUILDDIRS)
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(ALL_CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

# include additional rules after default rule!
-include $(DEPS)
