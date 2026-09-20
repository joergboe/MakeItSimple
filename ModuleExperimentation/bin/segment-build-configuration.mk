# Segment includes the project configuration and figure out bin directory, build directory and cache directory.
#
# required functions: info_i, info_d
#
# provided functions: resolve_path, prefix_dir and suffix_dir
#
# provided variables:
# bindir_res, builddir_res cache_res hcache_res:
# resolved relative path if below CURDIR, absolute otherwise; trailing / is removed
#
# binp, buildp and cachep hcachep:
# directory prefix ending with slash, empty if curdir
#
# bindir_ndot, builddir_ndot, cache_ndot hcache_ndot:
# empty if dot dir, dir otherwise
#
# builddirs: the list of all build sub directories below builddir
# cmidirs: list of all cache sub directories below cache
#
# request_header_translation: 1 if header translation is requested, empty otherwise
#
# user_mapping: 1 if we use a non default module mapping?

$(call info_d,Reading segment-build-configuration.mk)

# resolve_path - returns the list of resolved paths.
# The returned paths are absolute unless below CURDIR.
# usage: $(call resolved,file-list,option,error-message)
resolve_path = $(shell realpath $2 --relative-base=$(CURDIR) $1)$\
  $(if $(subst 0,,$(.SHELLSTATUS)),$(error ERROR: realpath returns failure '$(.SHELLSTATUS)' - $3 $1))

# prefix_dir - returns the empty string if input is dot and returns dir/ otherwise
# usage: $(call prefix_dir,dir)
prefix_dir = $(if $(subst .,,$1),$1/)

# suffix_dir - returns /$1 unless $1 is dot
# usage: $(call suffix_dir,dir)
suffix_dir = $(if $(subst .,,$1),/$1)

# read configuration from project file
MKTS_MAKEFILE_DEFS ?= project.mk
-include $(MKTS_MAKEFILE_DEFS)
$(if $(filter $(MKTS_MAKEFILE_DEFS),$(lastword $(MAKEFILE_LIST))),\
  $(call info_i,Included '$(MKTS_MAKEFILE_DEFS)')\
)

# Is header translation required?
request_header_translation ::=
ifneq ($(strip $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS)),)
  request_header_translation ::= 1
endif

# identifying bin directory build directory and module cache directory
BINDIR ?= bin
BUILDDIR ?= build
CXX_MODULE_CACHE ?= gcm.cache
CXX_HEADER_CACHE ?= gcm.cache
# TODO: Check BINDIR, BUILDDIR, CXX_MODULE_CACHE and CXX_HEADER_CACHE for empty string.

# resolve all directories and start sub-shell only once
build_bin_dir ::= $(call resolve_path,$(BINDIR) $(BUILDDIR) $(CXX_MODULE_CACHE) $(CXX_HEADER_CACHE),$\
  --canonicalize-missing,Resolving BINDIR BUILDDIR CXX_MODULE_CACHE CXX_HEADER_CACHE)

bindir_res ::= $(firstword $(build_bin_dir))
builddir_res ::= $(word 2,$(build_bin_dir))
cache_res ::= $(word 3,$(build_bin_dir))
hcache_res ::= $(lastword $(build_bin_dir))

binp ::= $(call prefix_dir,$(bindir_res))
buildp ::= $(call prefix_dir,$(builddir_res))
cachep ::= $(call prefix_dir,$(cache_res))
hcachep ::= $(call prefix_dir,$(hcache_res))

$(call info_i,Binay directory '$(bindir_res)'\
  $(nl)Build directory = '$(builddir_res)'\
  $(nl)Module cache directory '$(cache_res)')
$(if $(request_header_tr),$(call info_i,Header cache directory '$(hcache_res)'))

$(call info_d,binp = '$(binp)' buildp = '$(buildp)' cachep = '$(cachep)' hcachep = '$(hcachep)')

bindir_ndot ::= $(if $(subst .,,$(bindir_res)),$(bindir_res))
builddir_ndot ::= $(if $(subst .,,$(builddir_res)),$(builddir_res))
cache_ndot ::= $(if $(subst .,,$(cache_res)),$(cache_res))
hcache_ndot ::= $(if $(subst .,,$(hcache_res)),$(hcache_res))
$(call info_d,bindir_ndot = '$(bindir_ndot)' builddir_ndot = '$(builddir_ndot)' cache_ndot = '$(cache_ndot)' hcache_ndot = '$(hcache_ndot)')

user_mapping ::= $(if $(subst gcm.cache,,$(cache_res)),1,$(if $(CXX_SIMPLE_MAPPING),1))
ifneq ($(request_header_tr),)
  ifneq ($(cache_res),$(hcache_res))
    user_mapping ::= 1
  endif
endif

ifeq ($(user_mapping),)
  $(call info_i,Using default module mapping.)
else
  $(call info_i,Using user module mapping in cache directory '$(cache_res)')
  $(call info_i,Using $(if $(CXX_SIMPLE_MAPPING),simple,standart) module mapping.)
endif

segment-build-configuration = 1
