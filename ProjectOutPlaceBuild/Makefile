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

# include required project specific definitions
include $(makefile_defs)

# initialization block of the initial recursion level
ifndef MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD
  export MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD = 1

  # parallel execution is disabled in the first level invocation
  .NOTPARALLEL:

  define helpstring =
    This make script builds one executable defined through $$(BINDIR)/$$(TARGET) = $(BINDIR)/$(TARGET) from all %.cpp source
    files in all project source directories.

    Synopsis
        make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]
      or
        [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] make [make-options] [goal ...]

    Goals:
      all    Build the target executable - default goal.
      clean  Clean up the target executable and all build artefacts.
      help   Print this help text.

    Files:
      Makefile        This make script
      $(makefile_defs)      This required script contains the project customizations.
      $(makefile_warn)     If the default warning options are not sufficient, this optional file can be used to define
                      specific warning options and will be included from Makefile.

    Required customization variables:
      TARGET    Name of the executable to build.
      SRCDIRS   Space separated list of directories with c++ source files (Must contain at least '.')
      BUILDDIR  Directory used for build files (objects-files, dep-files)
      BINDIR    Target directory for the final executable

    Optional customization variables:
      BUILD_MODE:   Build mode set to 'run' or 'debug'.
      WARN_LEVEL:   Warning level set 0 .. 3.
      INCDIRS:      Space separated list of project internal include directories for the quote form of the include directive (-iquote)
                    Omit this variable, if header and source files are placed in the same directory.
      INCLUDE_DIRS: Space separated list of external include directories (-I).
      CPPFLAGS:     Extra compiler preprocessor options.
      CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
      TARGET_ARCH   Target specific flags.
      LDFLAGS:      Extra linker options, SUCH AS -L.
      LDLIBS:       Extra library flags given to the linker.

    Description:
      This make script builds one executable defined through $$(BINDIR)/$$(TARGET) = $(BINDIR)/$(TARGET) from all %.cpp source
      files in all project source directories.
      If variable BUILD_MODE is not set or has the value debug, the executables are build with debug information included.
      If variable BUILD_MODE=run optimized executables without debug information are built.

      The variable WARN_LEVEL can assign warning levels from 0 .. 3.
      The default warning level is 2 and activates a comprehensive set of warnings (for gcc).
      More compiler options can be given with variables INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS.

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

  export INC_FLAGS := $(addprefix -iquote,$(INCDIRS)) $(addprefix -I,$(INCLUDE_DIRS))

  # search source files and make dependent variables
  export BUILDDIRS := $(addprefix $(BUILDDIR)/,$(SRCDIRS))
  export CPPSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cpp))
  # with this code the cpp files are automatically and recursively detected
  #CPPSOURCES := $(shell find $(SRCDIRS) -name '*.cpp')
  export OBJECTS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.o))
  export DEPS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.d))

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
      $(info Build target $(BINDIR)/$(TARGET) from *.cpp sourcefiles in source directories: $(SRCDIRS))
      $(info All include directories: $(INCDIRS) $(INCLUDE_DIRS))
      $(info Detected objects: $(OBJECTS))
      $(info $(infostring))
      $(info )
      $(info  Building with WARN_LEVEL=$(WARN_LEVEL) included flags:)
      $(info $(cxxwarnings))
      $(info )
    endif
  endif

  export ALL_CXXFLAGS := -fmessage-length=0 $(cxxopt) $(cxxwarnings) $(CXXFLAGS)

endif

# With recursive variables the automatic variables are expanded during receipt execution.
all_cppflags = -MMD -MF"$(@:%.o=%.d)" -MP -MT"$@" $(CPPFLAGS) $(INC_FLAGS)

all:
	@$(MAKE) -f $(makefile_this) $(BINDIR)/$(TARGET)

clean:
	@echo 'Cleanup'
	-$(RM) $(BINDIR)/$(TARGET)
	-$(RM) -r $(BUILDDIR)
	-@echo

help:
	$(info )
	$(info $(helpstring))
	$(info )

$(BUILDDIRS):
	mkdir -p '$@'

$(BINDIR):
	mkdir -p '$@'

$(BINDIR)/$(TARGET): $(OBJECTS) | $(BINDIR)
	$(CXX) $(ALL_CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o "$@"
	@echo -e 'Finished linking target: $@\n'

$(OBJECTS): $(BUILDDIR)/%.o: %.cpp $(makefile_this) $(makefile_defs) | $(BUILDDIRS)
	$(CXX) $(ALL_CXXFLAGS) $(all_cppflags) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

# include additional rules after default rule!
-include $(DEPS)
