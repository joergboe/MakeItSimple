# Segment includes the project configuration and figure out build directory and cache directory.
#
# required functions: info_i, info_d
#
# provided variables:
# build mcache hcache:
# resolved relative path if below CURDIR, absolute otherwise; trailing / is removed
#
# build_p and mcache_p hcache_p:
# directory prefix ending with slash, empty if curdir
#
# build_ndot, mcache_ndot hcache_ndot:
# empty if dot dir, dir otherwise
#
# request_header_translation: 1 if header translation is requested, empty otherwise
#
# user_mapping: 1 if we use a non default module mapping?

$(call info_d,Reading segment-build-configuration.mk)
$(call info_i,)

# read configuration from project file
MKTS_MAKEFILE_DEFS ?= project.mk
-include $(MKTS_MAKEFILE_DEFS)
$(if $(filter $(MKTS_MAKEFILE_DEFS),$(lastword $(MAKEFILE_LIST))),\
  $(call info_i,Using project configuration '$(MKTS_MAKEFILE_DEFS)')\
,\
  $(call info_i,Using default configuration.)\
)

# Is header translation required?
request_header_translation ::=
ifneq ($(strip $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS)),)
  request_header_translation ::= 1
endif

# identifying build directory and module cache directory
BUILDDIR ?= build
CXX_MODULE_CACHE ?= gcm.cache
CXX_HEADER_CACHE ?= gcm.hcache

# All build directories must be reside below CURDIR and must be non empty.
temp = $(BUILDDIR) $(CXX_MODULE_CACHE) $(CXX_HEADER_CACHE)
ifneq ($(words $(temp)),3)
  $(error $(red)ERROR: Enter one valid value for BUILDDIR, CXX_MODULE_CACHE and CXX_HEADER_CACHE! '$(temp)'$(res))
endif

# resolve all directories and start sub-shell only once
temp2 ::= $(call resolve_path,$(temp),$\
  --canonicalize-missing,Resolving BUILDDIR CXX_MODULE_CACHE CXX_HEADER_CACHE)

build ::= $(word 1,$(temp2))
mcache ::= $(word 2,$(temp2))
hcache ::= $(word 3,$(temp2))

$(call info_i,Build directory = '$(build)'\
  $(nl)Module cache directory '$(mcache)')
$(if $(or $(request_header_translation),$(verbose)),$(call info_i,Header cache directory '$(hcache)'))

$(foreach type,build mcache hcache,\
  $(if $(patsubst ..%,,$($(type))),,$(error ERROR: $(type) must be reside below CURDIR! $(type) = '$($(type))'))\
)

build_p ::= $(call prefix_dir,$(build))
mcache_p ::= $(call prefix_dir,$(mcache))
hcache_p ::= $(call prefix_dir,$(hcache))

$(call info_d,build_p = '$(build_p)' mcache_p = '$(mcache_p)' hcache_p = '$(hcache_p)')

build_ndot ::= $(filter-out .,$(build))
mcache_ndot ::= $(filter-out .,$(mcache))
hcache_ndot ::= $(filter-out .,$(hcache))
$(call info_d,build_ndot = '$(build_ndot)' mcache_ndot = '$(mcache_ndot)' hcache_ndot = '$(hcache_ndot)')

user_mapping ::= $(if $(subst gcm.cache,,$(mcache)),1,$(if $(CXX_SIMPLE_MAPPING),1))
ifneq ($(request_header_translation),)
  ifneq ($(mcache),$(hcache))
    user_mapping ::= 1
  endif
endif

external_module_map ::=
ifneq ($(CXX_EXTERNAL_MODMAP),)
  external_module_map ::= $(wildcard $(CXX_EXTERNAL_MODMAP))
  ifneq ($(external_module_map),)
    user_mapping ::= 1
    $(call info_i,Using external module cmi files in $(external_module_map))
  else
    $(warning $(yel)WARNING: External module map '$(CXX_EXTERNAL_MODMAP)' does not exist! (CXX_EXTERNAL_MODMAP)$(res))
  endif
endif

# Non empty variable user_mapping indicates the need to use a user module mapper, not the default mapper.
ifeq ($(user_mapping),)
  $(call info_i,Using default module mapping. ('$(mcache)'))
else
  $(call info_i,Using user module mapping in cache directory '$(mcache)')
  $(call info_i,Kind (standart/simple) of module mapping : $(if $(CXX_SIMPLE_MAPPING),simple,standart))
endif

ifeq ($(request_header_translation),)
  $(call info_d,No header unit translation required.)
else
  $(call info_i,Header translation required.)
endif

$(call info_i,)

segment-build-configuration = 1
