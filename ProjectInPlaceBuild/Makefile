SHELL = /bin/bash

makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk
makefile_warn := warnings.mk

# deletes the old fashioned suffix rules from database (speedup)
.SUFFIXES:
# instructs make to delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:

.PHONY: all clean info help recursion_goal
# ensures that 'all' is the default (first target without a dot) goal
all:

# include required project specific definitions
include $(makefile_defs)

# The following initialization block is active in the initial recursion level only.
ifndef MAKE_IT_SIMPLE_PROJECT_IN_PLACE_BUILD
  export MAKE_IT_SIMPLE_PROJECT_IN_PLACE_BUILD = 1

  # Since the parallel execution is deactivated in the initial recursion level,
  # the execution of the command line goals is ensured in the intended order.
  .NOTPARALLEL:

  define helpstring =
    This make script builds one executable defined in variable $$(TARGET)=$(TARGET) from all %.cpp source files in the 
    current/project directory.

    Synopsis
        make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]
      or
        [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] make [make-options] [goal ...]

    Goals:
      all    Build the target executable - default goal.
      clean  Clean up the target executable and all build artefacts.
      info   Print project info.
      help   Print this help text.
      %.o    Build this object file if a coresponding %.cpp exists.

    Files:
      Makefile        This make script
      $(makefile_defs)      This required script contains the project customizations.
      $(makefile_warn)     If the default warning options are not sufficient, this optional file can be used to define
                      specific warning options and will be included from Makefile.

    Required customization variables:
      TARGET  Name of the executable to build.

    Optional customization variables:
      BUILD_MODE:   Build mode set to 'run' or 'debug'.
      WARN_LEVEL:   Warning level set 0 .. 3.
      INCLUDE_DIRS: Space separated list of external include directories (-I).
      CPPFLAGS:     Extra compiler preprocessor options.
      CXXFLAGS:     Extra c++ compiler options (use for linker and compiler).
      TARGET_ARCH:  Target specific flags.
      LDFLAGS:      Extra linker options, SUCH AS -L.
      LDLIBS:       Extra library flags given to the linker.

    Description:
      This make script builds one executable defined in variable $$(TARGET)=$(TARGET) from all %.cpp source files in the 
      current/project directory.
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

  # determines all required objects/flags and exports required values for recursion
  export CPPSOURCES := $(wildcard *.cpp)
  export OBJECTS := $(CPPSOURCES:.cpp=.o)
  export DEPS := $(CPPSOURCES:.cpp=.d)

  export INC_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))

  # the default warnings are:
  cxxwarn0 = -ftabstop=4
  cxxwarn1 = -pedantic -Wall -Wextra
  cxxwarn2 = -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wmissing-declarations \
  -Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion \
  -Wsign-conversion -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant \
  -Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
  cxxwarn3 = -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros -Wstrict-overflow=5

  # Overwrite warning definitions in file makefile_warn if defaults are not sufficient!
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
    modeinfostring := Building optimized release version
  else ifeq ($(BUILD_MODE),debug)
    cxxopt := -O0 -g3
    modeinfostring := Building with debug information
  else
    $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
  endif

  # prints info only if not silent (-s option) and not help goal or info goal
  ifeq (,$(findstring s,$(MAKEFLAGS)))
    ifeq (,$(or $(findstring help,($(MAKECMDGOALS))),$(findstring info,($(MAKECMDGOALS)))))
      $(info )
      $(info Detected objects : $(OBJECTS))
      $(info )
    endif
  endif

  export ALL_CXXFLAGS := -fmessage-length=0 $(cxxopt) $(cxxwarnings) $(CXXFLAGS)

endif

# With recursive variables the automatic variables are expanded during receipt execution.
all_cppflags = -MMD -MP $(CPPFLAGS) $(INC_FLAGS)

# rules:
all:
	@$(MAKE) -f $(makefile_this) $(TARGET)

clean:
	@echo 'Cleanup'
	-$(RM) $(TARGET) *.o *.d
	-@echo

info:
	$(info )
	$(info Detected objects :$(OBJECTS))
	$(info )
	$(info Target : $(TARGET))
	$(info )
	$(info $(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(cxxopt))
	$(info )
	$(info Building with WARN_LEVEL=$(WARN_LEVEL) : $(cxxwarnings))
	$(info )

help:
	$(info )
	$(info $(helpstring))
	$(info )

$(TARGET): $(OBJECTS)
	$(CXX) $(ALL_CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o "$@"
	@echo -e 'Finished linking target: $@\n'

$(OBJECTS): %.o: %.cpp $(makefile_this) $(makefile_defs)
	$(CXX) $(ALL_CXXFLAGS) $(all_cppflags) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

# includes additional rules after default rule
-include $(DEPS)
