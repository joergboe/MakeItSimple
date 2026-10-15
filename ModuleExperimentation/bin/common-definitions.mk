# Common function and variable definitions
#
# required variable: bin, silent
#
# provided color variables:
# red, yel, res
#
# provided generic variables:
# nl, empty, tab, space
#
# provided control variables:
# verbose, keep_going
#
# provided macros for recipes:
# spacer, echo_i, echo_d, ec
#
# provided functions for printouts:
# info_i, info_d
#
# provided generic functions:
# neq
#
# provided path manipulation functions:
# resolve_path, prefix_dir, suffix_dir, cat_dir, all_dirs
#
# provided command variables:
# SHELL, .SHELLFLAGS, RMDIR, MKDIR, RM
#

red =
yel =
res =
ifneq ($(MAKE_TERMERR),)
  red = [91m
  yel = [93m
  res = [0m
endif

# checking gnu make version
min_make_version = 4.4.1
ifeq ($(origin MAKE_VERSION),undefined)
  $(warning $(yel)WARNING: This is not GNU Make.$(res))
else ifneq ($(min_make_version),$(firstword $(sort $(MAKE_VERSION) $(min_make_version))))
  $(warning $(yel)WARNING: Required make version is $(min_make_version) or higher but version is $(MAKE_VERSION).$(res))
endif

# common variables
define nl


endef
empty =
tab ::= $(empty)	$(empty)
space ::= $(empty) $(empty)

# The output is verbose (debug level) if not -s and variable VERBOSE is not null.
verbose =
ifeq ($(silent),)
  ifneq ($(strip $(VERBOSE)),)
    verbose = -v
  endif
endif

# info_i - print info level information.
# usage: $(call info_i,message)
info_i = $(info $1)

# info_d - print debug level information.
# usage: $(call info_d,message)
info_d = $(info $1)

# spacer - print a newline in recipes
spacer = @echo

# echo_i - print in recipes
echo_i = @echo '$1'

# ec - control the echo in recipes
ec =

# justifying display macros
ifeq ($(verbose),)
  info_d =
  ec = @
endif
ifneq ($(silent),)
  info_i =
  echo_i =
  spacer =
endif

$(call info_d,Reading $(bin)common-definitions.mk)

# Macros to display information about the running recipe.
ifeq ($(silent),)
  due_to = @echo 'Run target '\''$@'\'' due to $?'
  run_tgt = @echo 'Run target '\''$@'\'
else
  due_to =
  run_tgt =
endif

# determine variable keep_going
keep_going =
ifeq (k,$(findstring k,$(single_make_options)))
  keep_going = 1
endif

# neq - The function expand to non-empty string if param1 and param2 are not equal or to the empty string otherwise.
# call neq,param1,param2
neq = $(or $(subst $2,,$1),$(subst $1,,$2))

# resolve_path - return the list of resolved paths
# The returned paths are relative to CURDIR.
# usage: $(call resolved,file-list,option,error-message)
resolve_path = $(shell realpath $2 --relative-to=$(CURDIR) $1)$\
  $(if $(subst 0,,$(.SHELLSTATUS)),$(error $(red)ERROR: realpath returns failure '$(.SHELLSTATUS)' - $3 $1$(res)))

# prefix_dir - The function returns the empty string if input is dot and returns dir/ otherwise.
# usage: $(call prefix_dir,dir)
prefix_dir = $(if $(call neq,.,$1),$1/)

# suffix_dir - The function returns the empty string if input is dot and returns /dir otherwise.
# usage: $(call suffix_dir,dir)
suffix_dir = $(if $(call neq,.,$1),/$1)

# cat_dir - The function concatenates two directory components and discards all dot directory components.
# usage: $(call cat_dir,dir1,dir2)
cat_dir = $(if $(call neq,.,$1),$\
  $(if $(call neq,.,$2),$1/$2,$1)$\
,$\
  $(if $(call neq,.,$2),$2)$\
)

# all_dirs - The function expands to the list of all (parent) directories of a path including the last slash.
# If path does not end with /, the last component is considered a file object.
# The last dot path is not reported.
# usage: $(call parent_dirs,path)
all_dirs = $(let dd,$(dir $1),$\
  $(if $(subst ./,,$(dd)),$\
    $(dd) $(call all_dirs,$(patsubst %/,%,$(dd)))$\
  )$\
)

# global settings
SHELL = /bin/bash
.SHELLFLAGS ::= -ec
RMDIR = rm -rf
MKDIR = mkdir
RM = rm -f

common-definitions = 1
