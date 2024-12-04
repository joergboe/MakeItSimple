# version
mktsimple_version = 4.0.1
# Prepare the help string if required
ifneq (,$(findstring help,$(MAKECMDGOALS)))
  define helpstring =

This make script builds one executable from all %.c source files in all project source
directories and creates a JSON Compilation Database ($(compile_database_name)) for the clang language
server.
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

Optional customization variables:
  TARGET              Name of the executable to build. Default value is the last path component of
                      this Makefile.
  SRCDIRS             Space separated list of directories with c source files.
                      Default value is 'src' (Use '.' for the project dir)
  INCDIRS:            Space separated list of project internal include directories for the quote form
                      of the include directive (-iquote) Omit this variable, if header and source files
                      are placed in the source directories. The default value is 'include' if this
                      directory exists, or the empty string if the directory not exists.
  INCSYSDIRS:         Space separated list of external include directories used with compiler option -I.
                      Default: empty.
  WARN_LEVEL:         Warning level set 0 .. 5. Default: 4
  MAKEFILE_WARN:      The name of the file with specific warning options. The default is 'mktsimple/warnings.xxxx.mk'
                      for a 'known' compiler or 'warnings.mk' for a unknown compiler. 'Known' compilers
                      are: gcc-7, gcc-12..14 and clang-13,14,17,18,19
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
  CFLAGS:             Extra c compiler options (use for linker and compiler).
  SRCxxxxFLAGS        Flags for one specific source file. xxxx stands for the name of the source file,
                      where periods and slashes are replaced by underscores.
  TARGET_ARCH:        Target specific flags.
  LDFLAGS:            Extra linker options, such as -L.
  LDLIBS:             Space separated list of libraries given to the linker (including -l).
  CC                  The compiler command to be used. Default: 'cc'
  DISABLE_CONFIG_CHECK: If set to anything other than the empty string, the configuration check is
                      disabled.

Description:
  This make script builds or updates one executable from all %.c source files in all project
  source directories. The name of the executable is defined through variable TARGET and the default
  is the last component of the directory which contains this Makefile (the project directory).
  The project may have separate header file directories. If the include directory differs from
  'include', set the name(s) in variable INCDIRS.

  This script checks the version of the compiler and searches for an appropriate 'warnings.xxxx.mk'
  file in the directories ./mktsimple and /usr/local/include/mktsimple. If the tool is installed in
  a different place than /usr/local/include or /usr/include, add the option '-I' with the path to the
  include directory of your installation e. g.: '-I ~/mktsimple/include'.

  If a 'production goal' (all compdb %.o..) runs and a configuration change has bee detected the
  compilation database is automatically created or updated.

  If variable BUILD_MODE is not set or has the value debug, the executables are build with debug
  information included.
  If variable BUILD_MODE equals 'run', optimized executables without debug information are built.

  The variable WARN_LEVEL can assign warning levels from 0 .. 5.
  The default warning level is 4 and activates a comprehensive set of warnings (for gcc and clang).

  By default the cc compiler is used. To use a different compiler, set variable CC. E.g 'CC=clang'

  Use the CFLAGS variable to change the c language standard. E.g. 'CFLAGS=-std=c11'.

  If parallel execution is requested (-j n), the script disallowes the congruent execution of clean-
  and production-goals.

  NOTE: The character set for file names is restricted. In particular, the following characters are
  not allowed in file names: whitespaces, #, ', ", %, :, ;, (, and )
  Allowed characters are: ?, *, $$, !, \, ~, &, ^, {, and }

  NOTE: xFLAGS that contain spaces, quotation marks, or other special shell characters must be
  quoted. If they are given as command line arguments, they must be qouted twice according to the
  rules of your shell! Example (for bash):
  CPPFLAGS='-D MYHELLO="\"External define!\"" -MJ$$@.jj -D MYHELLO2="\"Hello World #2\""' CC=clang

Some useful make-options:
  -h, --help                      Display help.
  -j [N], --jobs[=N]              Allow N jobs at once; infinite jobs with no arg.
  -k, --keep-going                Continue as much as possible after an error.
  -B, --always-make               Unconditionally make all targets.
  -r, --no-builtin-rules          Disable the built-in implicit rules.
  -s, --silent, --quiet           Don't echo recipes.
  -O[TYPE], --output-sync[=TYPE]  Synchronize output of parallel jobs by TYPE (none|line|target|recurse).
  -I dir, --include-dir=dir       Specifies a directory dir to search for included makefiles.

  endef
endif
# Prepare the info string if required
ifneq (,$(findstring show,$(MAKECMDGOALS)))
  define infostring =

Build target '$(BINDIR)/$(TARGET)' from *.cpp and *.cc sourcefiles in source directories : $(SRCDIRS))

Sources found : $(sort $(allsources))

Objects to build : $(sort $(objectsc))

All include directories (-iquote): $(INCDIRS)

All include (system) directories : $(INCSYSDIRS)

$(modeinfostring) : BUILD_MODE=$(BUILD_MODE) : $(bmodeflags)

Compiler command : $(CC)

Custom preprocessor options: $(CPPFLAGS)

Custom compiler options: $(CFLAGS)

Building with WARN_LEVEL=$(WARN_LEVEL) : $(cwarnings)

Warning level 1 includes : $(cwarn1)

Warning level 2 adds : $(cwarn2)

Warning level 3 adds : $(cwarn3)

Warning level 4 adds : $(cwarn4)

Warning level 5 adds : $(cwarn5)

The active warning include file is: $(MAKEFILE_WARN) $(if $(makefile_warn_used),, - does not exist!)
$(if $(makefile_warn_used),Used is file: $(makefile_warn_used))

All generated dependecies: $(sort $(depfiles))

Make It Simple version : $(mktsimple_version)

Make version : $(MAKE_VERSION)

  endef
endif

min_make_version = 4.2
ifeq ($(min_make_version),$(firstword $(sort $(MAKE_VERSION) $(min_make_version))))
else
  $(error ERROR: Required make version is $(min_make_version) or higher but version is $(MAKE_VERSION))
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

hidden_dir_name := .mktsimple
makefile_this := $(lastword $(MAKEFILE_LIST))
makefile_defs := project.mk
compile_database_name :=  compile_commands.json
last_config_store_name := mks_last_config_store
temp_config_store_name := mks_temp_config_store
gen_db_frag_file := $(hidden_dir_name)/mks_gen_db_frag.sh

single_make_options := $(firstword -$(MAKEFLAGS))
ifeq (s,$(findstring s,$(single_make_options)))
  silent_mode = 1
endif

# include project specific definitions if any
-include $(makefile_defs)

# call $1 - info string
conditional_info = $(if $(silent_mode),,$(info $1))
# get compiler name and version
# call $1 compiler command
get_comp_name_version = $(shell\
  ins=$$($1 --version);\
  if [[ "$${ins}" =~ (gcc|cc|clang).*[[:blank:]]+([[:digit:]]+)\.[[:digit:]]+\.[[:digit:]]+.* ]]; then\
    echo "$${BASH_REMATCH[1]} $${BASH_REMATCH[2]}";\
  fi)

# and add the defaults for the unset variables
ifndef MAKEFILE_WARN
  cc_name_vers := $(call get_comp_name_version,$(CC))
  ifneq (2,$(words $(cc_name_vers)))
    $(warning WARNING: Unknown compiler version $(CC) (cc_name_vers=$(cc_name_vers)) - using MAKEFILE_WARN=warnings.mk)
    MAKEFILE_WARN := warnings.mk
  else
    MAKEFILE_WARN := mktsimple/warnings.$(firstword $(cc_name_vers))-$(lastword $(cc_name_vers)).mk
  endif
endif
$(call conditional_info,Try using MAKEFILE_WARN=$(MAKEFILE_WARN))
WARN_LEVEL ?= 4
BUILD_MODE ?= debug
COMP_FLAGS_RUN ?= -O2 -g1
ifeq (,$(findstring clang,$(CC)))
  COMP_FLAGS_DEBUG ?= -Og -g3
else
  COMP_FLAGS_DEBUG ?= -Og -gline-tables-only
endif
formatflags ?= -ftabstop=4 -fmessage-length=0

# include warning definitions in file makefile_warn and complement default values
oldlist := $(MAKEFILE_LIST)
-include $(MAKEFILE_WARN)
ifeq ($(oldlist),$(MAKEFILE_LIST))
  $(warning WARNING: Warnings file $(MAKEFILE_WARN) does not exist! Did you forget the option -I <WarninsIncludeDir> ? (e.g.: -I ~/mktsimple/include))
  makefile_warn_used :=
else
  makefile_warn_used := $(lastword $(MAKEFILE_LIST))
  $(call conditional_info,Using warnings from $(makefile_warn_used))
endif
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
  cwarnings := $(cwarn0)
else ifeq ($(WARN_LEVEL),1)
  cwarnings := $(cwarn1)
else ifeq ($(WARN_LEVEL),2)
  cwarnings := $(cwarn1) $(cwarn2)
else ifeq ($(WARN_LEVEL),3)
  cwarnings := $(cwarn1) $(cwarn2) $(cwarn3)
else ifeq ($(WARN_LEVEL),4)
  cwarnings := $(cwarn1) $(cwarn2) $(cwarn3) $(cwarn4)
else ifeq ($(WARN_LEVEL),5)
  cwarnings := $(cwarn1) $(cwarn2) $(cwarn3) $(cwarn4) $(cwarn5)
else
  $(error ERROR: Invalid WARN_LEVEL=$(WARN_LEVEL))
endif

ifeq ($(BUILD_MODE),run)
  bmodeflags := $(COMP_FLAGS_RUN)
  modeinfostring := Building optimized release version
else ifeq ($(BUILD_MODE),debug)
  bmodeflags := $(COMP_FLAGS_DEBUG)
  modeinfostring := Building with debug information
else
  $(error ERROR: Build mode $(BUILD_MODE) is not supported. Use 'debug' or 'run')
endif

# allowed special characters in filenames are:
# ? * $ ! \ ~ & ^ { }
# disallowed are:
# # ' " % : ; ( ) and all kind of white space
# call name_has_char,name,char
name_has_char = $(if $(findstring $(2),$(1)),$(error ERROR: Invalid char $(2) in filename $(1)))
hs := \#
# call check_name,names
# quotes are paired to satisfy the syntax highlighter
check_name = $(foreach var,$(hs) ' ' " " % : ; ( ),$(call name_has_char,$(1),$(var)))

# determines all directories, sources, objects, dependecies, required flags
SRCDIRS ?= src
INCDIRS ?= $(wildcard include)
# get the last path component from the realpath of this filename as target name
TARGET ?= $(lastword $(subst /, ,$(dir $(realpath $(makefile_this)))))

BUILDDIR ?= $(BUILD_MODE)/build
BINDIR ?= $(BUILD_MODE)
builddirs := $(addprefix $(BUILDDIR)/,$(SRCDIRS))
sourcesc := $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))
# with this code the c files are recursively searched in the source directory list
#export sourcesc := $(shell find $(SRCDIRS) -name '*.c')
allsources := $(sourcesc)
# check for disallowed file names
$(foreach var,$(allsources),$(call check_name,$(var)))

objectsc := $(addprefix $(BUILDDIR)/,$(sourcesc:.c=.o))
depfiles := $(addprefix $(BUILDDIR)/,$(sourcesc:.c=.dep))
dbfragmentsc := $(addsuffix .mks.tmp,$(objectsc))
srcfakesc := $(addsuffix .mks.tmp,$(sourcesc))
incflags := $(addprefix -iquote,$(INCDIRS)) $(addprefix -I,$(INCSYSDIRS))
alltargets := $(objectsc) $(BINDIR)/$(TARGET)

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
      $(error ERROR: Cleanup and production is not allowed with parallel make enabled!)
    endif
  endif
endif
ifeq (purge,$(findstring purge,$(goals)))
  ifneq (,$(filter-out purge,$(goals)))
    $(error ERROR: purge must be the only goal!)
  endif
endif

# call OUTPUT_OPTION,outfile
OUTPUT_OPTION = -o $(1)
# OUTPUT_OPTION, allxxxflags and depflags go into the compilation database
allflags = $(CFLAGS) $(bmodeflags) $(incflags) $(CPPFLAGS) $(SRC$(subst /,_,$(subst .,_,$<))FLAGS)\
  $(cwarnings) $(formatflags) $(TARGET_ARCH) -c
depflags = -MMD -MF $(@:%.o=%.dep) -MP -MT $@

# prints info only if not silent (-s option) and not help goal or show goal
ifndef silent_mode
  ifeq (,$(or $(findstring help,$(MAKECMDGOALS)),$(findstring show,$(MAKECMDGOALS))))
    $(info )
    $(info Build target '$(BINDIR)/$(TARGET)' from *.c sourcefiles in source directories : $(SRCDIRS))
    $(info )
    $(info Sources found : $(sort $(allsources)))
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
BUILDDIR=$(BUILDDIR)
BINDIR=$(BINDIR)
CPPFLAGS=$(value CPPFLAGS)
CFLAGS=$(value CFLAGS)
TARGET_ARCH=$(value TARGET_ARCH)
LDFLAGS=$(value LDFLAGS)
LDLIBS=$(value LDLIBS)
CC=$(CC)
DISABLE_CONFIG_CHECK=$(DISABLE_CONFIG_CHECK)
OUTPUT_OPTION=$(value OUTPUT_OPTION)
cwarnings=$(strip $(cwarnings))
depflags=$(value depflags)
formatflags=$(value formatflags)
$(foreach var,$(filter SRC%FLAGS,$(.VARIABLES)),$(var)=$(value var)$(nl))
End.
endef

# Make hidden directory
ifneq (,$(or $(current_production_goals),$(current_target_goals)))
  $(shell $(MKDIR) '$(hidden_dir_name)')
  ifneq (0,$(.SHELLSTATUS))
    $(error ERROR: Can not create $(hidden_dir_name))
  endif
endif

# check configuration
ifdef DISABLE_CONFIG_CHECK
  last_config_store_target =
else
  last_config_store_target = $(hidden_dir_name)/$(last_config_store_name)
  # check for configuration changes only for production goals
  ifneq (,$(or $(current_production_goals),$(current_target_goals)))
    compare_configuration := $(file < $(hidden_dir_name)/$(last_config_store_name))
    prompt := No configuration change detected.
    ifneq ($(compare_configuration),$(configuration))
      # if configuration has changed: remove the configuration storage and store the temp_config_store
      prompt := Configuration has changed!
      $(shell $(RM) '$(hidden_dir_name)/$(last_config_store_name)')
      $(file > $(hidden_dir_name)/$(temp_config_store_name),$(configuration))
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
compile_source = $(CC)\
  $(foreach var,$(call OUTPUT_OPTION,$@) $<,'$(var)') $(allflags) $(foreach var,$(depflags),'$(var)')
gen_db_fragment = $(SHELL) -e $(gen_db_frag_file) '$(CURDIR)' $(CC)\
  $(foreach var,$(call OUTPUT_OPTION,$@) $<,'$(var)') $(allflags) $(foreach var,$(depflags),'$(var)')

# rules:
all: compdb build

build: $(BINDIR)/$(TARGET)

%: %.o
$(BINDIR)/$(TARGET): $(objectsc) | $(BINDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) $(TARGET_ARCH) $(foreach var,$^,'$(var)') $(LDLIBS) -o '$@'
	$(call conditional_echo,Finished linking target: $@\n)

%.o: %.c
$(objectsc): $(BUILDDIR)/%.o: %.c $(BUILDDIR)/%.dep $(makefile_this) $(last_config_store_target) | $(builddirs)
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

.INTERMEDIATE: $(srcfakesc)

$(compile_database_name): $(dbfragmentsc)
	@echo "[" > '$@'
	@sq=''; for x in $(foreach var,$^,'$(var)'); do \
	[[ -n $${sq} ]] && echo "," >> '$@'; cat "$$x" >> '$@'; sq=1; done
	@echo -e "\n]" >> '$@'
	$(call conditional_echo,Finished database $@\n)

$(dbfragmentsc): $(BUILDDIR)/%.o.mks.tmp: %.c.mks.tmp $(gen_db_frag_file) $(last_config_store_target)
	@$(gen_db_fragment)
	$(call conditional_echo,Finished database fragment $@)

$(srcfakesc): | $(builddirs)
	@touch '$@'

# when no configuration file exists, this rule and all depending rules are forced to run
$(last_config_store_target):
	-@$(MV) '$(hidden_dir_name)/$(temp_config_store_name)' '$@'
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
	-$(RM) '$(hidden_dir_name)/$(last_config_store_name)' '$(hidden_dir_name)/$(temp_config_store_name)' '$(compile_database_name)' '$(gen_db_frag_file)'
	-$(RMDIR) '$(BUILDDIR)' '$(BINDIR)' debug run
	-$(RMDIR) '$(hidden_dir_name)'
	$(call conditional_echo,)

show:
	$(info $(infostring))
	@$(CC) --version
	@echo

help:
	$(info $(helpstring))
