ifndef MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD
  define HELPSTRING =
    Build one executable defined through $$(BINDIR)/$$(TARGET) = $(BINDIR)/$(TARGET) from all %.cpp source files in a project source directories.

      make [makeoptions] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [more variables] [goal ...]

    Goals:
      all    Build the target executable - default goal.
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
    The variable WARN_LEVEL can assign warning levels from 0 .. 3.
    The default warning level is 2 and activates a comprehensive set of warnings (for gcc).
    More copiler options can be given with variables INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS.

    Variables:
      BUILD_MODE:   Build mode set to 'run' or 'debug'.
      WARN_LEVEL:   Warning level set 0 .. 3.
      INCLUDE_DIRS: Space separated list of external include directories (-I).
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

  THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

  # include project specific definitions
  include makefile.def
  export TARGET SRCDIRS INCDIRS BUILDDIR BINDIR
  # include warning definitions if defaults are not sufficient
  -include makefile.warn

  export INC_FLAGS := $(addprefix -I,$(INCDIRS)) $(addprefix -I,$(INCLUDE_DIRS))

  # search source files and make dependent variables
  export BUILDDIRS := $(addprefix $(BUILDDIR)/,$(SRCDIRS))
  export CPPSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cpp))
  # with this code the cpp files are automatically and recursively detected
  #CPPSOURCES := $(shell find $(SRCDIRS) -name '*.cpp')
  export OBJECTS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.o))
  export DEPS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.d))

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
    $(info Build target $(BINDIR)/$(TARGET) from *.cpp sourcefiles in source directories: $(SRCDIRS))
    $(info All include directories: $(INCDIRS) $(INCLUDE_DIRS))
    $(info Detected objects: $(OBJECTS))
    $(info $(INFOSTRING))
    $(info )
    $(info  Building with WARN_LEVEL=$(WARN_LEVEL) included flags:)
    $(info $(CXXWARNINGS))
    $(info )
  endif

  export ALL_CXXFLAGS := -fmessage-length=0 $(CXXOPT) $(CXXWARNINGS) $(CXXFLAGS)

.NOTPARALLEL:
endif

# cpp-flags require recursive variable flavor
ALL_CPPFLAGS = -MMD -MF"$(@:%.o=%.d)" -MP -MT"$@" $(CPPFLAGS) $(INC_FLAGS)

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: all clean help

all:
	@$(MAKE) MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD=1 -f $(THIS_MAKEFILE) $(BINDIR)/$(TARGET)

clean:
	@echo 'Cleanup'
	-$(RM) $(BINDIR)/$(TARGET)
	-$(RM) -r $(BUILDDIR)
	-@echo

help:
	$(info )
	$(info $(HELPSTRING))
	$(info )

$(BUILDDIRS):
	mkdir -p '$@'

$(BINDIR):
	mkdir -p '$@'

$(BINDIR)/$(TARGET): $(OBJECTS) | $(BINDIR)
	@echo 'Linking target: $@'
	$(CXX) $(ALL_CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o "$@"
	@echo -e 'Finished linking target: $@\n'

$(BUILDDIR)/%.o: %.cpp | $(BUILDDIRS)
	@echo 'Building file: $<'
	$(CXX) $(ALL_CXXFLAGS) $(ALL_CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

# include additional rules after default rule!
-include $(DEPS)
