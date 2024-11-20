# version
mktsimple_version = 4.0.0
# Prepare the help string if required
ifneq (,$(findstring help,$(MAKECMDGOALS)))
  define helpstring =

This make script builds one executable from all C++, C and assembler source files (%.cpp, %.cc, %.c
and %.s) in all project source directories and creates a JSON Compilation Database ($(compile_database_name))
for the clang language server.
The script supports 2 Build Modes (run and debug) and 6 Warning levels.
The script keeps track of the last used configuration in a file ($(last_config_store_name)). During
startup, the script checks the current build configuration. If a change in the build configuration
has been detected, a complete build of all targets is initiated.


Synopsis:
    make [make-options] [BUILD_MODE=debug|run] [WARN_LEVEL=[0..5]] [..] [goal ..]
  or
    [BUILD_MODE=debug|run] [WARN_LEVEL=[0..5]] [..] make [make-options] [goal ..]


Goals:
  all       Default goal - Build or update the target executable if outdated and build or update the
            JSON compilation database if neccessary.
  build     Build or update the target executable.
  compdb    Build or update the JSON Compilation Database if neccessary.
  clean     Clean up the target executable, object-files and dep-files of the current BUILD_MODE.
  purge     Clean up executables and all generated build artifacts, the compilation database
            and the configuration store.
  show      Print project info.
  help      Print this help text.
  dir/%.o   Build this object file if a coresponding source file exists.

Files:
  Makefile        This make script
  $(makefile_defs)      This optional script contains the project customizations.
  $$(MAKEFILE_WARN) If the default warning options are not sufficient, this optional file can be used to define
                  specific warning options and will be included from Makefile.
  $$(MAKEFILE_WARN_C) The optional file specific warning options for the C-compiler.

Optional customization variables:
  TARGET              Name of the executable to build. Default value is the last path component of
                      this Makefile.
  SRCDIRS             Space separated list of directories with c++/c/assembler source files
                      Default value is 'src' (Use '.' for the project dir)
  INCDIRS:            Space separated list of project internal include directories for the quote form
                      of the include directive (-iquote) Omit this variable, if header and source files
                      are placed in the source directories. The default value is 'inc*' or 'include*'
                      if any of these directories exist. If none of the directories exist the default
                      is the empty value.
  INCSYSDIRS:         Space separated list of external include directories used with compiler option -I.
                      Default: empty.
  WARN_LEVEL:         Warning level set 0 .. 5. Default: 4
  MAKEFILE_WARN:      The name of the file with specific warning options. Default: 'warnings.mk'
  MAKEFILE_WARN_C:    The name of the file with C-specific warning options. Default: 'warnings_c.mk'
  BUILD_MODE:         Build mode set to 'run' or 'debug'. Default: 'debug'
  COMP_FLAGS_RUN:     Compiler optimization level and debug option with BUILD_MODE = run.
                      Default: -O2 -g1 (clang: -Og -gline-tables-only)
  COMP_FLAGS_DEBUG:   Compiler optimization level and debug option with BUILD_MODE = debug.
                      Default: -Og -g3
  BUILDDIR            Directory used for build files (objects-files, dep-files).
                      Default: 'run/build or debug/build'
  BINDIR              Target directory for the final executable.
                      Default: run or debug
  CPPFLAGS:           Extra compiler preprocessor options.
  CXXFLAGS:           Extra c++ compiler options (use for linker and compiler).
  SRCxxxxFLAGS        Flags for one specific source file. xxxx stands for the name of the source file,
                      where periods and slashes are replaced by underscores.
  CFLAGS:             Extra c compiler options.
  ASFLAGS:            Extra assembler options.
  TARGET_ARCH:        Target specific flags for the c-, c++-compiler and linker.
  TARGET_MACH:        Target specific flags for the assembler.
  LDFLAGS:            Extra linker options, such as -L.
  LDLIBS:             Space separated list of libraries given to the linker.
  CXX                 The c++ compiler command to be used. Default: 'g++'
  CC                  The c compiler command to be used. Default: 'gcc'
  AS                  The assembler command to be used. Default: 'as'
  DISABLE_CONFIG_CHECK: If set to anything other than the empty string, the Compilation Database
                      generation is disabled.

Description:
  This make script builds or updates one executable from all %.cpp, %.cc, %.c and %.s source files in
  all project source directories. The name of the executable is defined through variable TARGET and
  the default is the last component of the directory which contains this Makefile.
  The project may have separate header file directories. If the include directory differs from
  'include*' or 'inc*', set the name in variable INCDIRS.

  This script checks the version of the compiler and searches for an appropriate 'warnings.xxxx.mk'
  file in directory /usr/local/include/mktsimple. If the tool is installed in a different place than
  /usr/local/include or /usr/include, add the base directory of the installation with make option -I.

  If a 'production goal' (all compdb %.o..) runs and a configuration change has bee detected the
  compilation database is automatically created or updated.

  If variable BUILD_MODE is not set or has the value debug, the executables are build with debug
  information included.
  If variable BUILD_MODE equals 'run', optimized executables without debug information are built.

  The variable WARN_LEVEL can assign warning levels from 0 .. 5.
  The default warning level is 4 and activates a comprehensive set of warnings (for gcc and clang).

  By default the g++ compiler is used. To use a different compiler, set variable CXX. E.g 'CXX=clang++'

  Use the CXXFLAGS, CFLAGS and ASSFLAGS variables to change the c++,c and assembler flags.
  E.g. 'CXXFLAGS=-std=c++11'.

  If parallel execution is requested (-j n), the script disallowes the congruent execution of clean-
  and production-goals.

  NOTE: The character set for file names is restricted. In particular, the following characters are
  not allowed in file names: whitespaces, #, ', ", %, :, ;, (, and )
  Allowed characters are: ?, *, $$, !, \, ~, &, ^, {, and }

  NOTE: xFLAGS that contain spaces, quotation marks, or other special shell characters must be
  quoted. If they are given as command line arguments, they must be qouted twice according to the
  rules of your shell! Example (for bash):
  CPPFLAGS='-D MYHELLO="\"External define!\"" -MJ$$@.jj -D MYHELLO2="\"Hello World #2\""' CXX=clang++ CC=clang

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
ifneq (,$(findstring show,$(MAKECMDGOALS)))
  define infostring =

Build target '$(BINDIR)/$(TARGET)' from *.cpp, *.cc, *.c and *.s sourcefiles in source directories : $(SRCDIRS)

Sources found : $(allsources)

Objects to build : $(objectscpp) $(objectscc) $(objectsc) $(objectsas)

All include directories (-iquote): $(INCDIRS)

All include (system) directories : $(INCSYSDIRS)

$(modeinfostring) : BUILD_MODE=$(BUILD_MODE)
c++ build options : $(bmodeflags)
c build options   : $(cbmodeflags)
as build options  : $(asbmodeflags)

Custom preprocessor options: $(CPPFLAGS)

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

Warning level 4 adds : $(cxxwarn4)
C-Warning flags : $(cwarn4)

Warning level 5 adds : $(cxxwarn5)
C-Warning flags : $(cwarn5)

The active C++ warning include file is: $(MAKEFILE_WARN) $(if $(makefile_warn_used),, - does not exist!)
$(if $(makefile_warn_used),Used is file: $(makefile_warn_used))
The active C warning include file is: $(MAKEFILE_WARN_C) $(if $(makefile_warn_c_used),, - does not exist!)
$(if $(makefile_warn_c_used),Used is file: $(makefile_warn_c_used))

All generated dependecies: $(depfiles)

Make It Simple version : $(mktsimple_version)

Make version : $(MAKE_VERSION)

  endef
endif

min_make_version = 4.2
ifeq ($(min_make_version),$(firstword $(sort $(MAKE_VERSION) $(min_make_version))))
else
  $(error required make version is $(min_make_version) or higher but version is $(MAKE_VERSION))
endif

production_goals = all build compdb
cleanup_goals = clean purge
action_goals = $(production_goals) $(cleanup_goals)
phony_goals = $(action_goals) show help

.SUFFIXES:        # deletes the old fashioned suffix rules from database (speedup)
.DELETE_ON_ERROR: # instructs make to delete the target of a rule if it has changed and its recipe
# exits with a nonzero status
.PHONY: $(phony_goals)
$(firstword $(action_goals)): # ensures that 'all' is the default (first target without a dot) goal

SHELL = /bin/bash
.SHELLFLAGS := -ec

# command definitions which are not in the default database
MV = mv -f
RMDIR = rm -rf
MKDIR = mkdir -p

makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk
compile_database_name :=  compile_commands.json
last_config_store_name := mks_last_config_store
temp_config_store_name := .mks_temp_config_store
gen_db_frag_file := mks_gen_db_frag.sh

single_make_options := $(firstword -$(MAKEFLAGS))
ifeq (s,$(findstring s,$(single_make_options)))
  silent_mode = 1
endif

# call $1 - info string
conditional_info = $(if $(silent_mode),,$(info $1))
# include optional project specific definitions
-include $(makefile_defs)

# get compiler name and version
# call $1 compiler command
get_comp_name_version = $(shell\
  ins=$$($1 --version);\
  if [[ "$${ins}" =~ (cc|gcc|g\+\+|clang).*[[:blank:]]+([[:digit:]]+)\.[[:digit:]]+\.[[:digit:]]+.* ]]; then\
    echo "$${BASH_REMATCH[1]} $${BASH_REMATCH[2]}";\
  fi)

# and add the defaults for the unset variables
ifndef MAKEFILE_WARN
  cc_name_vers := $(call get_comp_name_version,$(CXX))
  ifneq (2,$(words $(cc_name_vers)))
    $(warning Unknown compiler version $(CXX) (cc_name_vers=$(cc_name_vers)) - using MAKEFILE_WARN=warnings.mk)
    MAKEFILE_WARN := warnings.mk
  else
    MAKEFILE_WARN := mktsimple/warnings.$(firstword $(cc_name_vers))-$(lastword $(cc_name_vers)).mk
  endif
endif
$(call conditional_info,Try using MAKEFILE_WARN=$(MAKEFILE_WARN))
ifndef MAKEFILE_WARN_C
  cc_name_vers := $(call get_comp_name_version,$(CC))
  ifneq (2,$(words $(cc_name_vers)))
    $(warning Unknown compiler version $(CC) (cc_name_vers=$(cc_name_vers)) - using MAKEFILE_WARN_C=warnings_c.mk)
    MAKEFILE_WARN_C := warnings_c.mk
  else
    MAKEFILE_WARN_C := mktsimple/warnings.$(firstword $(cc_name_vers))-$(lastword $(cc_name_vers)).mk
  endif
endif
$(call conditional_info,Try using MAKEFILE_WARN_C=$(MAKEFILE_WARN_C))
WARN_LEVEL ?= 4
BUILD_MODE ?= debug
COMP_FLAGS_RUN ?= -O2 -g1
ifeq (,$(findstring clang,$(CXX)))
  COMP_FLAGS_DEBUG ?= -Og -g3
else
  COMP_FLAGS_DEBUG ?= -Og -gline-tables-only
endif
C_COMP_FLAGS_RUN ?= -O2 -g1
ifeq (,$(findstring clang,$(CC)))
  C_COMP_FLAGS_DEBUG ?= -Og -g3
else
  C_COMP_FLAGS_DEBUG ?= -Og -gline-tables-only
endif
AS_FLAGS_RUN ?= -O2
AS_FLAGS_DEBUG ?= -g
AS_FLAGS_LIST ?= -asli=$(@:%.o=%.lst)
formatflags ?= -ftabstop=4 -fmessage-length=0

# include warning definitions in file makefile_warn and complement default values
oldlist := $(MAKEFILE_LIST)
-include $(MAKEFILE_WARN)
makefile_warn_used := $(intcmp $(words $(MAKEFILE_LIST)),$(words $(oldlist)),,,$(lastword $(MAKEFILE_LIST)))
ifeq ($(oldlist),$(MAKEFILE_LIST))
  $(warning warnings file $(MAKEFILE_WARN) does not exist! Did you forget the option -I 'install_dir' ?)
  makefile_warn_used :=
else
  makefile_warn_used := $(lastword $(MAKEFILE_LIST))
  $(call conditional_info,Using warnings from $(makefile_warn_used))
endif
oldlist := $(MAKEFILE_LIST)
-include $(MAKEFILE_WARN_C)
makefile_warn_c_used := $(intcmp $(words $(MAKEFILE_LIST)),$(words $(oldlist)),,,$(lastword $(MAKEFILE_LIST)))
ifeq (,$(makefile_warn_c_used))
  $(warning warnings file $(MAKEFILE_WARN_C) does not exist! Did you forget the option -I 'install_dir' ?)
else
  $(call conditional_info,Using C warnings from $(makefile_warn_c_used))
endif
cxxwarn0 ?= -w
cxxwarn1 ?=
cxxwarn2 ?= -Wall
cxxwarn3 ?= -Wextra -Wpedantic
cxxwarn4 ?= -Wcast-align -Wconversion -Wctor-dtor-privacy -Wfloat-conversion -Wformat=2 -Wformat-nonliteral\
  -Wformat-security -Wformat-y2k -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnull-dereference\
  -Wold-style-cast -Wredundant-decls -Wsign-conversion -Wsign-promo -Wstrict-overflow=2 -Wsuggest-override
cxxwarn5 ?= -Waggregate-return -Walloca -Warray-bounds -Wattributes -Wcast-qual\
  -Wdate-time -Wdisabled-optimization -Weffc++ -Wfloat-equal\
  -Winline -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wpacked -Wpadded -Wregister -Wshadow\
  -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros -Wzero-as-null-pointer-constant

cwarn0 ?= -w
cwarn1 ?=
cwarn2 ?= -Wall
cwarn3 ?= -Wextra -Wpedantic
cwarn4 ?= -Wcast-align -Wconversion\
  -Wfloat-conversion -Wformat=2 -Wformat-nonliteral\
  -Wformat-security -Wformat-y2k\
  -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnull-dereference\
  -Wredundant-decls -Wsign-conversion\
  -Wstrict-overflow=2
cwarn5 ?= -Waggregate-return -Walloca\
  -Warray-bounds -Wattributes -Wcast-align -Wcast-qual\
  -Wdate-time -Wdisabled-optimization -Wfloat-equal\
  -Winline -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wpacked -Wpadded\
  -Wshadow -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros

ifeq ($(WARN_LEVEL),0)
  cxxwarnings := $(cxxwarn0)
  cwarnings := $(cwarn0)
  aswarnings := --no-warn
else ifeq ($(WARN_LEVEL),1)
  cxxwarnings := $(cxxwarn1)
  cwarnings := $(cwarn1)
  aswarnings := --no-warn
else ifeq ($(WARN_LEVEL),2)
  cxxwarnings := $(cxxwarn1) $(cxxwarn2)
  cwarnings := $(cwarn1) $(cwarn2)
  aswarnings := --warn
else ifeq ($(WARN_LEVEL),3)
  cxxwarnings := $(cxxwarn1) $(cxxwarn2) $(cxxwarn3)
  cwarnings := $(cwarn1) $(cwarn2) $(cwarn3)
  aswarnings := --warn
else ifeq ($(WARN_LEVEL),4)
  cxxwarnings := $(cxxwarn1) $(cxxwarn2) $(cxxwarn3) $(cxxwarn4)
  cwarnings := $(cwarn1) $(cwarn2) $(cwarn3) $(cwarn4)
  aswarnings := --warn
else ifeq ($(WARN_LEVEL),5)
  cxxwarnings := $(cxxwarn1) $(cxxwarn2) $(cxxwarn3) $(cxxwarn4) $(cxxwarn5)
  cwarnings := $(cwarn1) $(cwarn2) $(cwarn3) $(cwarn4) $(cwarn5)
  aswarnings := --warn
else
  $(error Invalid WARN_LEVEL=$(WARN_LEVEL))
endif

ifeq ($(BUILD_MODE),run)
  bmodeflags := $(COMP_FLAGS_RUN)
  cbmodeflags := $(C_COMP_FLAGS_RUN)
  asbmodeflags := $(AS_FLAGS_RUN)
  modeinfostring := Building optimized release version
else ifeq ($(BUILD_MODE),debug)
  bmodeflags := $(COMP_FLAGS_DEBUG)
  cbmodeflags := $(C_COMP_FLAGS_DEBUG)
  asbmodeflags := $(AS_FLAGS_DEBUG)
  modeinfostring := Building with debug information
else
  $(error Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
endif

# allowed special characters in filenames are:
# ? * $ ! \ ~ & ^ { }
# disallowed are:
# # ' " % : ; ( ) and all kind of white space
# call name_has_char,name,char
name_has_char = $(if $(findstring $(2),$(1)),$(error Invalid char $(2) in filename $(1)))
hs := \#
# call check_name,names
# quotes are paired to satisfy the syntax highlighter
check_name = $(foreach var,$(hs) ' ' " " % : ; ( ),$(call name_has_char,$(1),$(var)))

# determines all directories, sources, objects, dependecies, required flags
SRCDIRS ?= src
INCDIRS ?= $(wildcard include)
INCDIRS ?= $(wildcard inc)
# get the last path component from the realpath of this filename as target name
TARGET ?= $(lastword $(subst /, ,$(dir $(realpath $(makefile_this)))))

BUILDDIR ?= $(BUILD_MODE)/build
BINDIR ?= $(BUILD_MODE)
builddirs := $(addprefix $(BUILDDIR)/,$(SRCDIRS))
sourcescpp := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cpp))
sourcescc := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.cc))
# with this code the cpp files are recursively searched in the source directory list
#export sourcescpp := $(shell find $(SRCDIRS) -name '*.cpp')
sourcesc := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))
sourcesas := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.s))
allsources := $(sourcescpp) $(sourcescc) $(sourcesc) $(sourcesas)
# check for disallowed file names
$(foreach var,$(allsources),$(call check_name,$(var)))

objectscpp := $(addprefix $(BUILDDIR)/,$(sourcescpp:.cpp=.o))
objectscc := $(addprefix $(BUILDDIR)/,$(sourcescc:.cc=.o))
objectsc := $(addprefix $(BUILDDIR)/,$(sourcesc:.c=.o))
objectsas := $(addprefix $(BUILDDIR)/,$(sourcesas:.s=.o))
depfiles := $(addprefix $(BUILDDIR)/,$(sourcescpp:.cpp=.dep)) $(addprefix $(BUILDDIR)/,$(sourcescc:.cc=.dep))\
  $(addprefix $(BUILDDIR)/,$(sourcesc:.c=.dep))
dbfragmentscpp := $(addsuffix .mks.tmp,$(objectscpp))
dbfragmentscc := $(addsuffix .mks.tmp,$(objectscc))
dbfragmentsc := $(addsuffix .mks.tmp,$(objectsc))
srcfakescpp := $(addsuffix .mks.tmp,$(sourcescpp))
srcfakescc := $(addsuffix .mks.tmp,$(sourcescc))
srcfakesc := $(addsuffix .mks.tmp,$(sourcesc))
incflags := $(addprefix -iquote,$(INCDIRS)) $(addprefix -I,$(INCSYSDIRS))
alltargets := $(objectscpp) $(objectscc) $(objectsc) $(objectsas) $(BINDIR)/$(TARGET)

# check goals
goals := $(MAKECMDGOALS)
ifeq (,$(goals))
  goals := all
endif
current_production_goals = $(filter $(production_goals),$(goals))
current_target_goals = $(filter $(alltargets),$(goals))
current_cleanup_goals = $(filter $(cleanup_goals),$(goals))
# option -j is in makeflags in word after the single character options
ifeq (-j,$(findstring -j,$(filter -j%, $(MFLAGS))))
  ifneq (,$(current_cleanup_goals))
    ifneq (,$(or $(current_production_goals),$(current_target_goals)))
      $(error Cleanup and production is not allowed with parallel make enabled!)
    endif
  endif
endif
ifeq (purge,$(findstring purge,$(goals)))
  ifneq (,$(filter-out purge,$(goals)))
    $(error purge must be the only goal!)
  endif
endif

# call OUTPUT_OPTION,outfile
OUTPUT_OPTION = -o $(1)
# OUTPUT_OPTION and allxxxflags go into the compilation database, depflags don't'
allcxxflags = $(CXXFLAGS) $(bmodeflags) $(incflags) $(CPPFLAGS) $(SRC$(subst /,_,$(subst .,_,$<))FLAGS)\
  $(cxxwarnings) $(formatflags) $(TARGET_ARCH) -c
allcflags = $(CFLAGS) $(cbmodeflags) $(incflags) $(CPPFLAGS) $(SRC$(subst /,_,$(subst .,_,$<))FLAGS)\
  $(cwarnings) $(formatflags) $(TARGET_ARCH) -c
allasflags = $(ASFLAGS) $(asbmodeflags) $(SRC$(subst /,_,$(subst .,_,$<))FLAGS) $(aswarnings) -c
depflags = -MMD -MF $(@:%.o=%.dep) -MP -MT $@

# prints info only if not silent (-s option) and not help goal or show goal
ifndef silent_mode
  ifeq (,$(or $(findstring help,$(MAKECMDGOALS)),$(findstring show,$(MAKECMDGOALS))))
    $(info )
    $(info Build target '$(BINDIR)/$(TARGET)' from *.cpp, *.cc, *.c and *.s sourcefiles in source directories : $(SRCDIRS))
    $(info )
    $(info Sources found : $(allsources))
    $(info )
    $(info All include directories : $(INCDIRS) $(INCSYSDIRS))
    $(info )
  endif
endif

# new line required 2 lines!
define nl =


endef
# Recursive variables intended for expansion in a recipe must be saved as 'value'.
define configuration =
Last stored configuration:
TARGET=$(TARGET)
SRCDIRS=$(SRCDIRS)
INCDIRS=$(INCDIRS)
INCSYSDIRS=$(INCSYSDIRS)
BUILD_MODE=$(BUILD_MODE)
COMP_FLAGS_RUN=$(COMP_FLAGS_RUN)
COMP_FLAGS_DEBUG=$(COMP_FLAGS_DEBUG)
C_COMP_FLAGS_DEBUG=$(C_COMP_FLAGS_DEBUG)
C_COMP_FLAGS_RUN=$(C_COMP_FLAGS_RUN)
AS_FLAGS_RUN=$(AS_FLAGS_RUN)
AS_FLAGS_DEBUG=$(AS_FLAGS_DEBUG)
AS_FLAGS_LIST==$(value AS_FLAGS_LIST)
BUILDDIR=$(BUILDDIR)
BINDIR=$(BINDIR)
CPPFLAGS=$(value CPPFLAGS)
CXXFLAGS=$(value CXXFLAGS)
CFLAGS=$(value CFLAGS)
ASFLAGS=$(value ASFLAGS)
TARGET_ARCH=$(value TARGET_ARCH)
TARGET_MACH=$(value TARGET_MACH)
LDFLAGS=$(value LDFLAGS)
LDLIBS=$(value LDLIBS)
CXX=$(CXX)
CC=$(CC)
AS=$(AS)
DISABLE_CONFIG_CHECK=$(DISABLE_CONFIG_CHECK)
OUTPUT_OPTION=$(value OUTPUT_OPTION)
cxxwarnings=$(strip $(cxxwarnings))
cwarnings=$(strip $(cwarnings))
aswarnings=$(strip $(aswarnings))
depflags=$(value depflags)
formatflags=$(value formatflags)
$(foreach var,$(filter SRC%FLAGS,$(.VARIABLES)),$(var)=$(value var)$(nl))
End.
endef

ifdef DISABLE_CONFIG_CHECK
  last_config_store_target =
else
  last_config_store_target = $(last_config_store_name)
  # check for configuration changes only for production goals
  ifneq (,$(or $(current_production_goals),$(current_target_goals)))
    compare_configuration := $(file < $(last_config_store_name))
    prompt := No configuration change detected.
    ifneq ($(compare_configuration),$(configuration))
      # if configuration has changed: remove the configuration storage and store the temp_config_store
      prompt := Configuration has changed!
      $(shell $(RM) '$(last_config_store_name)')
      $(file > $(temp_config_store_name),$(configuration))
    endif
    ifndef silent_mode
      $(info $(prompt))
      $(info )
    endif
  endif
endif

# args: curdir cxx -o object.mks.tmp source.mks.tmp option1 ...
gen_db_frag_var = 'curdir="$${1}"'$$'\n'\
'shift'$$'\n'\
'{'$$'\n'\
'	echo "	{"'$$'\n'\
'	echo "		\"directory\": \"$${curdir}\","'$$'\n'\
'	echo "		\"file\": \"$${4%.mks.tmp}\","'$$'\n'\
'	echo -n "		\"arguments\": [ "'$$'\n'\
'	seq='\'\'$$'\n'\
'	declare -i i'$$'\n'\
'	for ((i=1; i<$$\#; i++)); do'$$'\n'\
'		if [[ -n "$$seq" ]]; then echo -n ", "; fi'$$'\n'\
'		seq=1'$$'\n'\
'		eval x="\$${$${i}}"'$$'\n'\
'		y="$${x//.mks.tmp/}"'$$'\n'\
'		echo -n "\"$${y//\"/\\\"}\""'$$'\n'\
'	done'$$'\n'\
'	echo " ],"'$$'\n'\
'	echo "		\"output\": \"$${3%.mks.tmp}\""'$$'\n'\
'	echo -n "	}"'$$'\n'\
'} > "$${3}"'$$'\n'

# call conditional_echo,string
ifndef silent_mode
  conditional_echo = @echo -e "$(1)"
else
  conditional_echo =
endif
# depflags, output option and source are single quoted
compile_source = $(my_cc)\
  $(foreach var,$(call OUTPUT_OPTION,$@) $<,'$(var)') $(my_flags) $(foreach var,$(my_depflags),'$(var)')
gen_db_fragment = $(SHELL) -e $(gen_db_frag_file) '$(CURDIR)' $(my_cc)\
  $(foreach var,$(call OUTPUT_OPTION,$@) $<,'$(var)') $(my_flags) $(foreach var,$(my_depflags),'$(var)')

# rules:
all: compdb build

build: $(BINDIR)/$(TARGET)

%: %.o
$(BINDIR)/$(TARGET): $(objectscpp) $(objectscc) $(objectsc) $(objectsas) | $(BINDIR)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH) $(foreach var,$^,'$(var)') $(LDLIBS) -o '$@'
	$(call conditional_echo,Finished linking target: $@\n)

%.o: %.cpp
$(objectscpp): my_cc = $(CXX)
$(objectscpp): my_flags = $(allcxxflags)
$(objectscpp): my_depflags = $(depflags)
$(objectscpp): $(BUILDDIR)/%.o: %.cpp $(BUILDDIR)/%.dep $(makefile_this) $(last_config_store_target) | $(builddirs)
	$(compile_source)
	$(call conditional_echo,Finished building: $<\n)

%.o: %.cc
$(objectscc): my_cc = $(CXX)
$(objectscc): my_flags = $(allcxxflags)
$(objectscc): my_depflags = $(depflags)
$(objectscc): $(BUILDDIR)/%.o: %.cc $(BUILDDIR)/%.dep $(makefile_this) $(last_config_store_target) | $(builddirs)
	$(compile_source)
	$(call conditional_echo,Finished building: $<\n)

%.o: %.c
$(objectsc): my_cc = $(CC)
$(objectsc): my_flags = $(allcflags)
$(objectsc): my_depflags = $(depflags)
$(objectsc): $(BUILDDIR)/%.o: %.c $(BUILDDIR)/%.dep $(makefile_this) $(last_config_store_target) | $(builddirs)
	$(compile_source)
	$(call conditional_echo,Finished building: $<\n)

%.o: %.s
$(objectsas): my_cc = $(AS)
$(objectsas): my_flags = $(allasflags)
$(objectsas): my_depflags = $(AS_FLAGS_LIST)
$(objectsas): $(BUILDDIR)/%.o: %.s $(makefile_this) $(last_config_store_target) | $(builddirs)
	$(compile_source)
	$(call conditional_echo,Finished building: $<\n)

$(builddirs):
	$(MKDIR) '$@'

$(BINDIR):
	$(MKDIR) '$@'

$(depfiles):

# includes additional rules after default rule
include $(wildcard $(depfiles))

compdb: $(compile_database_name)

.INTERMEDIATE: $(srcfakescpp) $(srcfakescc) $(srcfakesc)

$(compile_database_name): $(dbfragmentscpp) $(dbfragmentscc) $(dbfragmentsc)
	@echo "[" > '$@'
	@sq=''; for x in $(foreach var,$^,'$(var)'); do \
	[[ -n $${sq} ]] && echo "," >> '$@'; cat "$$x" >> '$@'; sq=1; done
	@echo -e "\n]" >> '$@'
	$(call conditional_echo,Finished database $@\n)

$(dbfragmentscpp): my_cc = $(CXX)
$(dbfragmentscpp): my_flags = $(allcxxflags)
$(dbfragmentscpp): my_depflags = $(depflags)
$(dbfragmentscpp): $(BUILDDIR)/%.o.mks.tmp: %.cpp.mks.tmp $(gen_db_frag_file) $(last_config_store_target)
	@$(gen_db_fragment)
	$(call conditional_echo,Finished database fragment $@)

$(dbfragmentscc): my_cc = $(CXX)
$(dbfragmentscc): my_flags = $(allcxxflags)
$(dbfragmentscc): my_depflags = $(depflags)
$(dbfragmentscc): $(BUILDDIR)/%.o.mks.tmp: %.cc.mks.tmp $(gen_db_frag_file) $(last_config_store_target)
	@$(gen_db_fragment)
	$(call conditional_echo,Finished database fragment $@)

$(dbfragmentsc): my_cc = $(CC)
$(dbfragmentsc): my_flags = $(allcflags)
$(dbfragmentsc): my_depflags = $(depflags)
$(dbfragmentsc): $(BUILDDIR)/%.o.mks.tmp: %.c.mks.tmp $(gen_db_frag_file) $(last_config_store_target)
	@$(gen_db_fragment)
	$(call conditional_echo,Finished database fragment $@)

$(srcfakescpp) $(srcfakescc) $(srcfakesc): | $(builddirs)
	@touch '$@'

# when no configuration file exists, this rule and all depending rules are forced to run
$(last_config_store_target):
	-@$(MV) '$(temp_config_store_name)' '$@'
	$(call conditional_echo,Configuration file $@ written\n)

$(gen_db_frag_file): $(makefile_this)
	@echo $(gen_db_frag_var) > '$@'
	$(call conditional_echo,Script file $@ written\n)

clean:
	$(call conditional_echo,Cleanup)
	-$(RM) $(foreach var,$(alltargets) $(depfiles),'$(var)')
	$(call conditional_echo,)

purge: clean
	$(call conditional_echo,Cleanup configuration store and compilation database)
	-$(RM) '$(last_config_store_name)' '$(temp_config_store_name)' '$(compile_database_name)' '$(gen_db_frag_file)'
	-$(RMDIR) '$(BUILDDIR)' '$(BINDIR)' debug run
	$(call conditional_echo,)

show:
	$(info $(infostring))
	@$(CXX) --version
	@echo

help:
	$(info $(helpstring))
