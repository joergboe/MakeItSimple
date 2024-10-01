# defines this help text string in the initial recursion level only
ifndef MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD_RECURSION
  # Prepare the help string if required
  ifneq (,$(findstring help,$(MAKECMDGOALS)))
  define helpstring =

This make script builds one executable from all C++, C and assembler source files (%.cpp, %.cc, %.c and %.s) in all project source directories
and maintains a JSON Compilation Database ($(compile_database_name)) for the clang language server.
The script supports 2 Build Modes (run and debug) and 4 Warning levels.
The Compilation Database is automatically updated when the configuration has changed.

Synopsis
    make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] [goal ...]
  or
    [BUILD_MODE=debug|run] [WARN_LEVEL=0|1|2|3] make [make-options] [goal ...]

Goals:
  all       Build the target executable - default goal.
  clean     Clean up the target executable, object-files and dep-files of the current BUILD_MODE.
  clean_all Clean up all build- and bin-directories and Compilation Database.
  info      Print project info.
  help      Print this help text.

Files:
  Makefile        This make script
  $(makefile_defs)      This optional script contains the project customizations.
  $$(MAKEFILE_WARN) If the default warning options are not sufficient, this optional file can be used to define
                  specific warning options and will be included from Makefile.

Optional customization variables:
  TARGET              Name of the executable to build. Default value is the last path component of this Makefile.
  SRCDIRS             Space separated list of directories with c++ source files (Must contain at least '.'). Default value is 'src'
  INCDIRS:            Space separated list of project internal include directories for the quote form of the include directive (-iquote)
                      Omit this variable, if header and source files are placed in the source dierectories. The default value
                      is 'inc' or 'include' if any of these directories exist. If none of the directories exist the default
                      is the empty value.
  INCSYSDIRS:         Space separated list of external include directories used with compiler option -I. Default: empty.
  WARN_LEVEL:         Warning level set 0 .. 3. Default: 2
  MAKEFILE_WARN:      The name of the file with specific warning options. Default: 'warnings.mk'
  BUILD_MODE:         Build mode set to 'run' or 'debug'. Default: 'debug'
  COMP_OPT_RUN:       Compiler optimization level and debug option with BUILD_MODE = run. Default: -O2 -g1 (clang: -Og -gline-tables-only)
  COMP_OPT_DEBUG:     Compiler optimization level and debug option with BUILD_MODE = debug. Default: -Og -g3
  BUILDDIR            Directory used for build files (objects-files, dep-files). Default: 'run|debug/build'
  BINDIR              Target directory for the final executable. Default: run|debug
  CPPFLAGS:           Extra compiler preprocessor options.
  CXXFLAGS:           Extra c++ compiler options (use for linker and compiler).
  CFLAGS:             Extra c compiler options (use for linker and compiler).
  ASFLAGS:            Extra assembler options (use for linker and compiler).
  TARGET_ARCH:        Target specific flags for the c-, c++-compiler and linker.
  TARGET_MACH:        Target specific flags for the assembler.
  LDFLAGS:            Extra linker options, such as -L.
  LDLIBS:             Space separated list of libraries given to the linker.
  CXX                 The c++ compiler command to be used. Default: 'g++'
  CC                  The c compiler command to be used. Default: 'gcc'
  AS                  The assembler command to be used. Default: 'as'
  DISABLE_COMPILE_DB: If set to anything other than the empty string, the Compilation Database generation is disabled.

Description:
  This make script builds one executable from all %.cpp, %.cc, %.c and %.s source files in all project source directories. The name of
  the executable is defined through variable TARGET and the default is the last component of the directory which contains
  this Makefile.
  The project may have a separate header file directory. If the include directory differs from 'include' or 'inc', set the
  name in variable INCDIRS.

  The Compilation Database is updated in allmost all cases if variable DISABLE_COMPILE_DB is unset.
  The exceptions from this rule are:
    * the goal 'clean_all' is the last or only command-line goal,
    * the goal 'help' is the only command-line goal.

  If variable BUILD_MODE is not set or has the value debug, the executables are build with debug information included.
  If variable BUILD_MODE equals 'run', optimized executables without debug information are built.

  The variable WARN_LEVEL can assign warning levels from 0 .. 3.
  The default warning level is 2 and activates a comprehensive set of warnings (for gcc and clang).

  By default the g++ compiler is used. To use a different compiler, set variable CXX. E.g 'CXX=clang++'

  Use the CXXFLAGS variable to change the c++ language standard. E.g. 'CXXFLAGS=-std=c++11'.

  If parallel execution is requested, the script executes the command line goals in the designated order and switches
  for goal 'all' to parallel execution mode in recursion level 1.

Some useful make-options:
  -h, --help                      Display help.
  -j [N], --jobs[=N]              Allow N jobs at once; infinite jobs with no arg.
  -k, --keep-going                Continue as much as possible after an error.
  -B, --always-make               Unconditionally make all targets.
  -r, --no-builtin-rules          Disable the built-in implicit rules.
  -s, --silent, --quiet           Don't echo recipes.
  -O[TYPE], --output-sync[=TYPE]  Synchronize output of parallel jobs by TYPE (none|line|target|recurse).

    endef
  endif
  # Prepare the info string if required
  ifneq (,$(findstring info,$(MAKECMDGOALS)))
    define infostring =

Build target '$(BINDIR)/$(TARGET)' from *.cpp, *.cc, *.c and *.s sourcefiles in source directories : $(SRCDIRS)

Sources found : $(CPPSOURCES) $(CCSOURCES) $(CSOURCES) $(ASMSOURCES)

Objects to build : $(OBJECTSCPP) $(OBJECTSCC) $(OBJECTSC) $(OBJECTSASM)

All include directories (-iquote): $(INCDIRS)

All include (system) directories : $(INCSYSDIRS)

$(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(CXXOPT)

C++ compiler command : $(CXX)

Custom C++ compiler options: $(CXXFLAGS)

C Compiler command : $(CC)

Custom C compiler options: $(CFLAGS)

Assembler command : $(AS)

Assembler options: $(ASFLAGS)

Building with WARN_LEVEL=$(WARN_LEVEL) : $(cxxwarnings)

C-Warning flags : $(cwarnings)

Warning level 1 includes : $(cxxwarn1)
C-Warning flags : $(cwarn1)

Warning level 2 adds : $(cxxwarn2)
C-Warning flags : $(cwarn2)

Warning level 3 adds : $(cxxwarn3)
C-Warning flags : $(cwarn3)

The active warning include file is: $(MAKEFILE_WARN)

All generated dependecies: $(DEPS)

    endef
  endif
endif

# Common initialization for both recursion levels
SHELL = /bin/bash
.SHELLFLAGS := -c

# deletes the old fashioned suffix rules from database (speedup)
.SUFFIXES:
# instructs make to delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:

.PHONY: all clean clean_all info help
# ensures that 'all' is the default (first target without a dot) goal
all:

# command definitions which are not in the default database
RMDIR = rm -rf
MKDIR = mkdir -p

makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk
# include optional project specific definitions
-include $(makefile_defs)
# and add the defaults for the unset variables

compile_database_name := compile_commands.json
ifndef DISABLE_COMPILE_DB
  compile_database_target := $(compile_database_name)
endif

ifeq (s,$(findstring s,$(firstword $(MAKEFLAGS))))
  silent_mode = 1
endif
# The new line variable requires 2 empty lines!
define new_line :=


endef

# The following initialization block is active in the initial recursion level only.
ifndef MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD_RECURSION
  export MAKE_IT_SIMPLE_PROJECT_OUT_PLACE_BUILD_RECURSION = 1

  # Since the parallel execution is deactivated in the initial recursion level,
  # the execution of the command line goals is ensured in the intended order.
  .NOTPARALLEL:

  # and add the defaults for the unset variables
  SRCDIRS ?= src
  INCDIRS ?= $(wildcard include)
  INCDIRS ?= $(wildcard inc)
  WARN_LEVEL ?= 2
  MAKEFILE_WARN ?= warnings.mk
  BUILD_MODE ?= debug
  COMP_OPT_RUN ?= -O2 -g1
  ifeq (,$(findstring clang,$(CXX)))
    COMP_OPT_DEBUG ?= -Og -g3
  else
    COMP_OPT_DEBUG ?= -Og -gline-tables-only
  endif
  AS_OPT_RUN ?= -O2
  AS_OPT_DEBUG ?= -g
  BUILDDIR ?= $(BUILD_MODE)/build
  BINDIR ?= $(BUILD_MODE)
  # get the last path component from the realpath of this filename as target name
  TARGET ?= $(lastword $(subst /, ,$(dir $(realpath $(makefile_this)))))

  # include warning definitions in file makefile_warn and complement default values
  -include $(MAKEFILE_WARN)
  cxxwarn0 ?= -ftabstop=4
  cxxwarn1 ?= -pedantic -Wall -Wextra
  cxxwarn2 ?= -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wmissing-declarations\
-Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion\
-Wsign-conversion -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant\
-Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
  cxxwarn3 ?= -Wswitch-default -Wswitch-enum -Wsign-promo -Wpadded -Weffc++ -Winline -Winvalid-pch -Wunused-macros -Wstrict-overflow=5

  cwarn0 ?= -ftabstop=4
  cwarn1 ?= -pedantic -Wall -Wextra
  cwarn2 ?= -Wcast-align -Wcast-qual -Wformat=2 -Winit-self -Wmissing-declarations\
-Wmissing-include-dirs -Wredundant-decls -Wshadow -Wconversion\
-Wsign-conversion -Wundef -Wfloat-equal -Winline\
-Wstrict-overflow=4 -Wdate-time -Wnull-dereference -Wdisabled-optimization
  cwarn3 ?= -Wswitch-default -Wswitch-enum -Wpadded -Winline -Winvalid-pch -Wunused-macros -Wstrict-overflow=5

  ifeq ($(WARN_LEVEL),0)
    cxxwarnings := $(cxxwarn0)
    cwarnings := $(cwarn0)
  else ifeq ($(WARN_LEVEL),1)
    cxxwarnings := $(cxxwarn1) $(cxxwarn0)
    cwarnings := $(cwarn1) $(cwarn0)
  else ifeq ($(WARN_LEVEL),2)
    cxxwarnings := $(cxxwarn2) $(cxxwarn1) $(cxxwarn0)
    cwarnings := $(cwarn2) $(cwarn1) $(cwarn0)
  else ifeq ($(WARN_LEVEL),3)
    cxxwarnings := $(cxxwarn3) $(cxxwarn2) $(cxxwarn1) $(cxxwarn0)
    cwarnings := $(cwarn3) $(cwarn2) $(cwarn1) $(cwarn0)
  else
    $(error Invalid WARN_LEVEL=$(WARN_LEVEL))
  endif

  ifeq ($(BUILD_MODE),run)
    bmodeflags := $(COMP_OPT_RUN)
    export ASOPT := $(AS_OPT_RUN)
    modeinfostring := Building optimized release version
  else ifeq ($(BUILD_MODE),debug)
    bmodeflags := $(COMP_OPT_DEBUG)
    export ASOPT := $(AS_OPT_DEBUG)
    modeinfostring := Building with debug information
  else
    $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
  endif

  # determines all directories, sources, objects, dependecies, required flags and exports values for recursion
  export BUILDDIRS := $(addprefix $(BUILDDIR)/,$(SRCDIRS))
  export CPPSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cpp))
  # with this code the cpp files are recursively searched in the source directory list
  #export CPPSOURCES := $(shell find $(SRCDIRS) -name '*.cpp')
  export CCSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cc))
  export CSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))
  export ASMSOURCES := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.s))
  export OBJECTSCPP := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.o))
  export OBJECTSCC := $(addprefix $(BUILDDIR)/,$(CCSOURCES:.cc=.o))
  export OBJECTSC := $(addprefix $(BUILDDIR)/,$(CSOURCES:.c=.o))
  export OBJECTSASM := $(addprefix $(BUILDDIR)/,$(ASMSOURCES:.s=.o))
  export DEPS := $(addprefix $(BUILDDIR)/,$(CPPSOURCES:.cpp=.d)) $(addprefix $(BUILDDIR)/,$(CCSOURCES:.cc=.d)) $(addprefix $(BUILDDIR)/,$(CSOURCES:.c=.d))
  export INC_FLAGS := $(addprefix -iquote,$(INCDIRS)) $(addprefix -I,$(INCSYSDIRS))
  incflags := $(addprefix -iquote,$(INCDIRS)) $(addprefix -I,$(INCSYSDIRS))
  libflags := $(addprefix -l,$(LDLIBS))
  #all_sources := $(CPPSOURCES) $(CCSOURCES)

  # prints info only if not silent (-s option) and not help goal or info goal
  ifndef silent_mode
    ifeq (,$(or $(findstring help,$(MAKECMDGOALS)),$(findstring info,$(MAKECMDGOALS))))
      $(info )
      $(info Build target '$(BINDIR)/$(TARGET)' from *.cpp, *.cc and *.c sourcefiles in source directories : $(SRCDIRS))
      $(info )
      $(info Sources found : $(CPPSOURCES) $(CCSOURCES) $(CSOURCES) $(ASMSOURCES))
      $(info )
      $(info All include directories : $(INCDIRS) $(INCSYSDIRS))
      $(info )
    endif
  endif

  export ALLSTATFLAGS := $(CXXFLAGS) $(bmodeflags) $(incflags) $(CPPFLAGS) $(cxxwarnings) -fmessage-length=0 $(LDFLAGS) $(libflags) $(TARGET_ARCH) -c

  # compiler database functions
  actiongoals = $(filter-out help info,$(MAKECMDGOALS))
  ifeq (clean_all,$(lastword $(actiongoals)))
    finally_delete_database = 1
  else ifneq (help,$(MAKECMDGOALS))
    ifndef DISABLE_COMPILE_DB
      source_list_tail := $(lastword $(all_sources))
      source_list_head := $(filter-out $(source_list_tail),$(all_sources))

      # call file_entry,sourcename
      define file_entry =
 {
    "directory": "$(PWD)",
    "arguments": [$(foreach var,$(subst ",\",$(CXX) $(ALLSTATFLAGS)),"$(var)",) "-o", "$(1)", "$(basename $(1))"],
    "file": "$(1)",
    "output": "$(basename $(1))"
  }
      endef

      compile_database := [$(new_line)\
        $(foreach var,$(source_list_head), $(call file_entry,$(var)),$(new_line))\
        $(call file_entry,$(source_list_tail))$(new_line)]

      compare_database := $(file < $(compile_database_name))
      prompt := Compile Database is up to date.
      ifneq ($(compare_database),$(compile_database))
        prompt := Write Compile Database!
        $(file > $(compile_database_name),$(compile_database))
      endif
      # prints info only if not silent (-s option)
      ifndef silent_mode
        $(info $(prompt))
        $(info )
      endif
    endif
  endif
endif

my_cxxflags := -fmessage-length=0 $(CXXOPT) $(cxxwarnings)
my_cflags := -fmessage-length=0 $(CXXOPT) $(cwarnings)
# With recursive variables the automatic variables are expanded during receipt execution.
my_cppflags = -MMD -MF"$(@:%.o=%.d)" -MP -MT"$@" $(INC_FLAGS)
my_asflags = -asli="$(@:%.o=%.lst)" $(ASOPT)

# rules:
all:
	@$(MAKE) -f $(makefile_this) $(BINDIR)/$(TARGET)

$(BUILDDIRS):
	$(MKDIR) '$@'

$(BINDIR):
	$(MKDIR) '$@'

$(BINDIR)/$(TARGET): $(OBJECTSCPP) $(OBJECTSCC) $(OBJECTSC) $(OBJECTSASM)| $(BINDIR)
	$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ $(LDLIBS) -o "$@"
	@echo -e 'Finished linking target: $@\n'

$(OBJECTSCPP): $(BUILDDIR)/%.o: %.cpp $(makefile_this) | $(BUILDDIRS)
	$(CXX) $(my_cxxflags) $(CXXFLAGS) $(my_cppflags) $(CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

$(OBJECTSCC): $(BUILDDIR)/%.o: %.cc $(makefile_this) | $(BUILDDIRS)
	$(CXX) $(my_cxxflags) $(CXXFLAGS) $(my_cppflags) $(CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

$(OBJECTSC): $(BUILDDIR)/%.o: %.c $(makefile_this) | $(BUILDDIRS)
	$(CC) $(my_cflags) $(CFLAGS) $(my_cppflags) $(CPPFLAGS) $(TARGET_ARCH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

$(OBJECTSASM): $(BUILDDIR)/%.o: %.s $(makefile_this) | $(BUILDDIRS)
	$(AS) $(my_asflags) $(ASFLAGS) $(TARGET_MACH) -c -o "$@" "$<"
	@echo -e 'Finished building: $<\n'

# includes additional rules after default rule
-include $(DEPS)

clean:
	@echo 'Cleanup'
	-$(RM) $(BINDIR)/$(TARGET)
	-$(RMDIR) $(BUILDDIR)
	-@echo

clean_all:
	@echo 'Remove all build dirs'
	-$(RMDIR) $(BUILDDIR) $(BINDIR) debug run
	-@echo

info:
	$(info )
	$(info Build target '$(BINDIR)/$(TARGET)' from *.cpp, *.cc, *.c and *.s sourcefiles in source directories : $(SRCDIRS))
	$(info )
	$(info Sources found : $(CPPSOURCES) $(CCSOURCES) $(CSOURCES) $(ASMSOURCES))
	$(info )
	$(info Objects to build : $(OBJECTSCPP) $(OBJECTSCC) $(OBJECTSC) $(OBJECTSASM))
	$(info )
	$(info All include directories (-iquote): $(INCDIRS))
	$(info )
	$(info All include (system) directories : $(INCSYSDIRS))
	$(info )
	$(info $(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(CXXOPT))
	$(info )
	$(info C++ compiler command : $(CXX))
	$(info )
	$(info Custom C++ compiler options: $(CXXFLAGS))
	$(info )
	$(info C Compiler command : $(CC))
	$(info )
	$(info Custom C compiler options: $(CFLAGS))
	$(info )
	$(info Assembler command : $(AS))
	$(info )
	$(info Assembler options: $(ASFLAGS))
	$(info )
	$(info Building with WARN_LEVEL=$(WARN_LEVEL) : $(cxxwarnings))
	$(info )
	$(info C-Warning flags : $(cwarnings))
	$(info )
	$(info Warning level 1 includes : $(cxxwarn1))
	$(info C-Warning flags : $(cwarn1))
	$(info )
	$(info Warning level 2 adds : $(cxxwarn2))
	$(info C-Warning flags : $(cwarn2))
	$(info )
	$(info Warning level 3 adds : $(cxxwarn3))
	$(info C-Warning flags : $(cwarn3))
	$(info )
	$(info The active warning include file is: $(MAKEFILE_WARN))
	$(info )
	$(info All generated dependecies: $(DEPS))
	$(info )
	@$(CXX) --version
ifdef CSOURCES
	@$(CC) --version
endif
ifdef ASMSOURCES
	@$(AS) --version
endif
	@echo -e '*********************************************\n'

help:
	$(info )
	$(info $(helpstring))
	$(info )
