# Common definitions

# provided variables: nl, empty, tab, space
# provided variables: verbose
# provided macros: spacer, echo_i, echo_d, ec
# provided functions: info_i, info_d
# provided functions: resolve_path, prefix_dir, suffix_dir, cat_dir, cat_build_list_suffix

red =
yel =
res =
ifneq ($(MAKE_TERMERR),)
  red = [91m
  yel = [93m
  res = [0m
endif

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

# info_i : Prints info level information.
# usage: $(call info_i,message)
info_i = $(info $1)

# info_d : Prints debug level information.
# usage: $(call info_d,message)
info_d = $(info $1)

# spacer : print a newline in recipes
spacer = @echo

# echo_i
echo_i = @echo '$1'

# controls the echo of a recipe
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

$(call info_d,Reading $(bin)definitions.mk)

# macro to display information
ifeq ($(silent),)
  due_to = @echo 'Run target '\''$@'\'' due to $?'
  run_tgt = @echo 'Run target '\''$@'\'
else
  due_to =
  run_tgt =
endif

# resolve_path - returns the list of resolved paths.
# The returned paths are relative to CURDIR.
# usage: $(call resolved,file-list,option,error-message)
resolve_path = $(shell realpath $2 --relative-to=$(CURDIR) $1)$\
  $(if $(subst 0,,$(.SHELLSTATUS)),$(error $(red)ERROR: realpath returns failure '$(.SHELLSTATUS)' - $3 $1$(res)))

# neq - expands to non-empty string if param1 and param2 are not equal or to the empty string otherwise
# call neq,param1,param2
neq = $(or $(subst $2,,$1),$(subst $1,,$2))

# prefix_dir - returns the empty string if input is dot and returns dir/ otherwise
# usage: $(call prefix_dir,dir)
prefix_dir = $(if $(call neq,.,$1),$1/)

# suffix_dir - returns /$1 unless $1 is dot
# usage: $(call suffix_dir,dir)
suffix_dir = $(if $(call neq,.,$1),/$1)

# cat_dir - concatenates two directory components and discards dot directory components
# usage: $(call cat_dir,dir1,dir2)
cat_dir = $(if $(call neq,.,$1),$\
  $(if $(call neq,.,$2),$1/$2,$1)$\
,$\
  $(if $(call neq,.,$2),$2)$\
)

# all_dirs - expands to the list of all (parent) directories of a path including the last slash
# If path does not end with /, the last component is considered a file object.
# The last dot path is not reported.
# usage: $(call parent_dirs,path)
all_dirs = $(let dd,$(dir $1),$\
  $(if $(subst ./,,$(dd)),$\
    $(dd) $(call all_dirs,$(patsubst %/,%,$(dd)))$\
  )$\
)

definitions = 1
