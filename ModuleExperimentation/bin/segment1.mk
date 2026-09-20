# Segment 1

# provided variables: nl, empty, tab, space
# provided functions: info_i, info_d
# provided variables: silent, verbose, spacer, echo_i and ec


define nl


endef
empty =
tab ::= $(empty)	$(empty)
space ::= $(empty) $(empty)

# info_i : Prints info level information.
# usage: $(call info_i,message)
info_i = $(info $1)

# info_d : Prints debug level information.
# usage: $(call info_d,message)
info_d =

# spacer : print a newline in recipes
spacer = @echo

# echo_i
echo_i = $(if $(silent),,@echo '$1')

# ec controls the echo of a recipe line.
ec =

# checking command-line option -s
single_make_options ::= $(firstword -$(MAKEFLAGS))
# defining conditional info and echo functions
ifeq (s,$(findstring s,$(single_make_options)))
  silent = 1
  info_i =
  spacer =
  ec = @
else
  silent =
endif

# print verbose (debug level) if not -s and variable VERBOSE is not null
verbose =
ifeq ($(silent),)
  ifneq ($(VERBOSE),)
    ifneq ($(strip $(VERBOSE)),)
      verbose = -v
      info_d = $(info $1)
    endif
  endif
endif

$(call info_d,Reading segment1.mk)

# macro to display information
ifeq ($(silent),)
  due_to = @echo 'Run target $@ due to $?.'
else
  due_to =
endif

segment1 = 1
