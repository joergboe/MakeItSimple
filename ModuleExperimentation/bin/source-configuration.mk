# Source file configuration
#

$(call info_d,Reading $(bin)source-configuration.mk)

# identifying source directories and source files
# srcdirs: resolved relative path of source directories if below CRDIR absolute otherwise, trailing / is removed
MKTS_CXX_SUFFIXES ?= *.cc *.cxx *.cpp *.CPP *.c++ *.C

ifeq ($(strip $(SOURCES)),)
  # no sources entered
  ifeq ($(strip $(SRCDIRS)),)
    SRCDIRS = src
  endif

  srcdirs ::= $(call resolve_path,$(SRCDIRS),--canonicalize-existing,Resolving SRCDIRS =)
  $(call info_i,Source directories resolved: '$(srcdirs)'.)
  ifneq ($(words $(SRCDIRS)),$(words $(sort $(srcdirs))))
    $(error $(red)ERROR: Duplicates in resolved SRCDIRS: '$(srcdirs)'$(res))
  endif

  $(call info_d,Source file search pattern MKTS_CXX_SUFFIXES = '$(MKTS_CXX_SUFFIXES)')
  all_source_patterns ::= $(foreach dir,$(srcdirs),$(addprefix $(call prefix_dir,$(dir)),$(MKTS_CXX_SUFFIXES)))
  $(call info_d,all_source_patterns = '$(all_source_patterns)')

  sources ::= $(wildcard $(all_source_patterns))
  $(call info_i,Sources found: '$(sources)')

else
  # sources are entered
  ifneq ($(strip $(SRCDIRS)),)
    $(if $(cleanup),,\
      $(error $(red)ERROR: SRCDIRS and SOURCES are defined! One of SRCDIRS and SOURCES is sufficient.$(res)))
  else
    sources ::= $(call resolve_path,$(SOURCES),--canonicalize-existing,Resolving SOURCES =)
    $(call info_i,Source files resolved: '$(sources)')
    ifneq ($(words $(SOURCES)),$(words $(sort $(sources))))
      $(if $(cleanup),,$(error $(red)ERROR: Duplicate in resolved SOURCES: '$(sources)'$(res)))
    endif

    srcdirs ::= $(patsubst %/,%,$(sort $(dir $(sources))))
    $(call info_i,Source directories found: '$(srcdirs)')

  endif
endif
$(call info_i,)

srcdirs_ndot ::= $(strip $(filter-out .,$(srcdirs)))
$(call info_d,srcdirs_ndot = '$(srcdirs_ndot)')

# filtering out the pathes which are not below CURDIR
not_below_curdir ::= $(strip $(foreach dir,$(srcdirs),$(filter ..%,$(dir))))
$(call info_d,not_below_curdir = '$(not_below_curdir)')

# warn if not_below_curdir and (build eq . or mcache eq .)
# warn if not (all_below_curdir or (build neq . and mcache neq .))
all_src_below_curdir ::= $(if $(not_below_curdir),,1)
$(if $(or $(all_src_below_curdir),$(and $(call neq,$(build),.),$(call neq,$(mcache),.))),,\
  $(warning $(yel)WARNING: If sources are not below CURDIR, the usage of a dedicated build and module cache dorectory is\
  recommended!$(res))\
)

# get_path_to_level_zero - return the path n times $(name)/ where n is the number of leading .. components in $(path)
# assuming that .. components are only at the beginning of the path
# usage: $(call get_path_to_level_zero,path,name)
get_path_to_level_zero = $(let comp rest,$(subst /, ,$1),$\
  $(if $(call neq,..,$(comp)),,$2/$(if $(rest),$(call get_path_to_level_zero,$(rest),$2)))$\
)

# determining the longest path of .. components in all source directories
all_paths_to_level_zero ::= $(foreach dir,$(not_below_curdir),$(call get_path_to_level_zero,$(dir),z))
$(call info_d,all_paths_to_level_zero = '$(all_paths_to_level_zero)')
path_to_level_zero ::= $(lastword $(sort $(all_paths_to_level_zero)))
$(call info_d,path_to_level_zero = '$(path_to_level_zero)')

# Build Base Directory bbd
bbd_p ::= $(build_p)$(path_to_level_zero)
bbd_ndot ::= $(patsubst %/,%,$(bbd_p))
bbd ::= $(if $(bbd_ndot),$(bbd_ndot),.)
$(call info_i,Build Base Directory = '$(bbd)')
$(call info_d,bbd_ndot = '$(bbd_ndot)' bbd_p = '$(bbd_p)')

# Module Cache Base Directory
ifneq ($(CXX_SIMPLE_MAPPING),)
  mcbd_p ::= $(mcache_p)$(path_to_level_zero)
  mcbd_ndot ::= $(patsubst %/,%,$(mcbd_p))
  mcbd ::= $(if $(mcbd_ndot),$(mcbd_ndot),.)
else
  mcbd_p ::= $(mcache_p)
  mcbd_ndot ::= $(mcache_ndot)
  mcbd ::= $(mcache)
endif
$(call info_i,Module Cache Base Directory = '$(mcbd)')
$(call info_d,mcbd_ndot = '$(mcbd_ndot)' mcbd_p = '$(mcbd_p)')

# identifying the list of build sub directories
buildsub ::= $(srcdirs)
buildsub_ndot ::= $(srcdirs_ndot)
$(call info_d,buildsub = '$(buildsub)')
$(call info_d,buildsub_ndot = '$(buildsub_ndot)')

# identifying the list of potential extra cmi sub directories
ifneq ($(CXX_SIMPLE_MAPPING),)
  cmisub ::= $(buildsub)
  cmisub_ndot ::= $(buildsub_ndot)
else
  cmisub ::=
  cmisub_ndot ::=
endif
$(call info_d,cmisub = '$(cmisub)')
$(call info_d,cmisub_ndot = '$(cmisub_ndot)')
$(call info_i,)

source-configuration = 1
