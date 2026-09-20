# The projects with C++ modules using secondary expansion
# see: Skeleton-Makefile2sec-auto.mk

# The makefile implements 2 custom module mappings:
#    If CXX_SIMPLE_MAPPING is undefined the name of the cmi file is         modulecache/<modulname>.gcm
#    If CXX_SIMPLE_MAPPING has a nonempty value the name of the cmi file is modulecache/<sourcefile>.gcm

# With CXX_SIMPLE_MAPPING=1:
# Problem with grouped pattern rule dependency propagation. (delete src1.o src2.o)

# checking gnu make version
min_make_version = 4.4.1
ifeq ($(origin MAKE_VERSION),undefined)
  $(warning WARNING: This is not GNU Make.)
else ifneq ($(min_make_version),$(firstword $(sort $(MAKE_VERSION) $(min_make_version))))
  $(warning WARNING: Required make version is $(min_make_version) or higher but version is $(MAKE_VERSION).)
endif

# get path of this makefile
this_makefile ::= $(lastword $(MAKEFILE_LIST))
bin ::= $(dir $(this_makefile))

# including functions and variables
include $(bin)segment1.mk
.PHONY : $(bin)segment1.mk
$(if $(segment1),,$(error ERROR: segment1.mk not included))

# intro
$(call info_i,$(nl)$(if $(MAKE_RESTARTS),RESTART # $(MAKE_RESTARTS),START) $(this_makefile) in $(CURDIR).$(nl))

# global settings
SHELL = /bin/bash
.SHELLFLAGS ::= -ec
RMDIR = rm -rf
MKDIR = mkdir
RM = rm -f
# remove all the built-in pattern rules
MAKEFLAGS += -r
.DELETE_ON_ERROR:

# default target
.PHONY : all
all : all_

# do not try update makefiles
$(bin)Makefile-mod-2sec.mk : ;

# checking goals
cleanup_goals = clean purge clean-header-units
goals = $(MAKECMDGOALS)
# The variable cleanup is also used to prevent inclusion of dependent makefiles.
cleanup ::= $(filter $(cleanup_goals),$(goals))
ifneq ($(cleanup),)
  ifneq (,$(filter-out $(cleanup_goals),$(goals)))
    $(error ERROR: The goals '$(cleanup_goals)' must not be used in conjunction with other targets.)
  endif
endif

# reading configuration from project file and figure out bin directory, build directory and cache directory
include $(bin)segment-build-configuration.mk
.PHONY : $(bin)segment-build-configuration.mk
$(if $(segment-build-configuration),,$(error ERROR: segment-build-configuration.mk not included))

# identifying source directories and source files
# srcdirs_res: resolved relative path of source directories if below CRDIR absolute otherwise, trailing / is removed
MKTS_CXX_SUFFIXES ?= *.cc *.cxx *.cpp *.CPP *.c++ *.C

ifeq ($(strip $(SOURCES)),)
  # no sources entered
  ifeq ($(strip $(SRCDIRS)),)
    SRCDIRS = src
  endif

  srcdirs_res ::= $(call resolve_path,$(SRCDIRS),--canonicalize-existing,Resolving SRCDIRS =)
  $(call info_i,Source directories resolved: '$(srcdirs_res)'.)
  ifneq ($(words $(SRCDIRS)),$(words $(sort $(srcdirs_res))))
    $(error ERROR: Duplicates in resolved SRCDIRS: '$(srcdirs_res)')
  endif

  $(call info_d,Source file search pattern MKTS_CXX_SUFFIXES = '$(MKTS_CXX_SUFFIXES)')
  all_source_pattern ::= $(foreach dir,$(srcdirs_res),$\
    $(addprefix $(call prefix_dir,$(dir)),$(MKTS_CXX_SUFFIXES))$\
  )
  $(call info_d,all_source_pattern = '$(all_source_pattern)')

  sources_int ::= $(wildcard $(all_source_pattern))
  $(call info_i,Sources found: '$(sources_int)')

else
  # sources are entered
  ifneq ($(strip $(SRCDIRS)),)
    $(error ERROR: SRCDIRS and SOURCES are defined! One of SRCDIRS and SOURCES is sufficient.)
  else
    sources_int ::= $(call resolve_path,$(SOURCES),--canonicalize-existing,Resolving SOURCES =)
    $(call info_i,Source files resolved: '$(sources_int)')
    ifneq ($(words $(SOURCES)),$(words $(sort $(sources_int))))
      $(error ERROR: Duplicate in resolved SOURCES: '$(sources_int)')
    endif

    srcdirs_res ::= $(patsubst %/,%,$(sort $(dir $(sources_int))))
    $(call info_d,Source directories found: '$(srcdirs_res)')

  endif
endif

$(call info_d,srcdirs_res = '$(srcdirs_res)')

srcdirs_ndot ::= $(strip $(filter-out .,$(srcdirs_res)))
$(call info_d,srcdirs_ndot = '$(srcdirs_ndot)')

builddirs = $(srcdirs_ndot)
$(call info_d,build sub dirs = '$(builddirs)')

# identifying the list of potential extra cmi sub directories
ifneq ($(CXX_SIMPLE_MAPPING),)
  cmidirs = $(srcdirs_ndot)
else
  cmidirs =
endif
$(call info_d,cmi sub dirs = '$(cmidirs)')

# get the last path component from the current project directory as target name
TARGET ?= $(lastword $(subst /, ,$(CURDIR)))
$(call info_i,Build target '$(binp)$(TARGET)')

# make header unit cmi files - must run once for productive goals at start up
header_unit_target ::=
ifndef MAKE_RESTARTS
  ifneq ($(request_header_translation),)
    header_unit_target ::= $(buildp)header-cmis.txt

    $(buildp)header-cmis.txt ::
	$(ec)$(MAKE) -f $(bin)Makefile-header-units.mk
	$(spacer)
  endif
endif

# directory rules
$(builddir_ndot) :
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

$(addprefix $(buildp),$(builddirs)) : | $(builddir_ndot)
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

$(bindir_ndot) :
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

ifneq ($(cache_res),$(builddir_res))
  $(cache_ndot) :
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)

  $(addprefix $(cachep),$(cmidirs)) : | $(cache_ndot)
	$(ec)dir=; for x in $(subst /, ,$@); do dir+="$${dir}$${x}/"; $(MKDIR) $(verbose) "$${dir}"; done
	$(spacer)
endif

# required compiler options
infoflags =
ifneq ($(verbose),)
  infoflags = -flang-info-include-translate -flang-info-module-cmi
endif

# rule to generate dependency files
depfiles ::= $(addprefix $(buildp),$(addsuffix .dep,$(sources_int)))
$(depfiles) : $(buildp)%.dep : % | $(header_unit_target)
	$(due_to)
	$(ec)$(CXX) '$<' -MM -MF '$@' -MQ '$@' -fdeps-format=p1689r5 -fdeps-file='$(buildp)$*.ddi' -fdeps-target='$(buildp)$*.o' -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(ec)$(bin)p1689_to_make_sec.sh '$(buildp)$*.ddi' '$@' '$(buildp)$*.o' '$<'
	$(spacer)

.SECONDEXPANSION :

# append directory prerequisites to depfile rules
$(depfiles) : $(buildp)%.dep : | $$(subst .,,$$(@D))

# cmi_mapper - map module name or source file name to the cmi file name for project modules
# input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  cmi_mapper = $(cachep)$(subst :,-,$1).gcm
else
  cmi_mapper = $(cachep)$(src).gcm
endif

# mapper file dependency
mapper_dep = $(if $(user_mapping),$(buildp)module-map.txt)

# mapper option
mapper_opt = $(if $(user_mapping),-fmodule-mapper=$(buildp)module-map.txt)

# include all depfiles with provided modules database: CXX_SRC_MOD_IF_LIST
# depfiles require cmi_mapper function
# CXX_MOD_require1_CMI variables are resolved during secondary expansion
CXX_SRC_MOD_IF_LIST ::= # prefer simple variable favor for the list with provided modules
ifeq ($(cleanup),)
  include $(depfiles)
endif
ifneq ($(verbose),)
  $(info CXX_SRC_MOD_IF_LIST ::=)
  $(foreach var,$(CXX_SRC_MOD_IF_LIST),$(info $(tab)$(var)))
endif

# template rule for module sources
# input: src - source file name
#        obj - object name
#        dep - depfile name
#        cmi - cmi file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  define modul_rule_template
  $(call info_i,generate module rule $(obj) $(cmi) &: $(src) $(dep) $(mapper_dep) | $(cache_ndot))

  $$(obj) $$(cmi) : my_obj ::= $$(obj)
  $$(obj) $$(cmi) &: $$(subst $$$$,$$$$$$$$,$$(src) $$(dep)) $$$$(mapper_dep) | $$$$(cache_ndot)
	$$(due_to)
	$(ec)$$(CXX) -o '$$(my_obj)' '$$<' -c $$(mapper_opt) $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) $$(infoflags)
	$(spacer)
  endef
else
  modul_rule_template =
endif

# TODO: generate variables and modulemap for imported cmi files

# generate rules for module sources, module variables and module map and check for duplicate module
# provided variables:
#        src - source file name
#        mod - the module name
#        is_if - is interface (0/1)
#        modi - internal module name (colon is replaced with dash)
#        cmi  - cmi name
#        obj - object name
#        dep - defile name
modsources ::= # generate rules for module sources and module variables for the output variables
nomodsources ::=
modulemap ::=
ifeq ($(strip $(CXX_SRC_MOD_IF_LIST)),)
  $(call info_i,No module database!)
endif
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi obj dep,$(subst :,-,$(mod)) $(call cmi_mapper,$(mod),$(src)) $(buildp)$(src).o $(buildp)$(src).dep,\
        $(if $(CXX_MOD_$(modi)_CMI),\
          $(error Duplicate module $(mod) in source unit $(src))\
        )\
        $(call info_i,CXX_MOD_$(modi)_CMI ::= $(cmi))\
        $(eval CXX_MOD_$$(modi)_CMI ::= $$(cmi))\
        $(eval modsources += $$(src))\
        $(eval modulemap += $$(mod);$$(cmi))\
        $(eval $(modul_rule_template))\
      )\
    ,\
      $(eval nomodsources += $$(src))\
    )\
  )\
)
# TODO: keep going for duplicate modules check
$(call info_i,modsources = '$(modsources)')
$(call info_i,nomodsources = '$(nomodsources)')

# TODO: generate variables and modulemap for imported cmi files

# write module-map - avoid unnecessary updates
# NOTE: trailing spaces are not allowed
modulemap_subst ::= $(subst ;, ,$(subst $(space),$(nl),$(modulemap)))
modulemap_old ::= $(file < $(buildp)module-map.txt)
ifneq ($(modulemap_old),$(modulemap_subst))
  $(call info_i,Write modulemap '$(buildp)module-map.txt'.)
  $(file > $(buildp)module-map.txt,$(modulemap_subst))
endif
# TODO: write empty modulemap

# generate rules for no module sources
nomodobjects ::= $(addprefix $(buildp),$(addsuffix .o,$(nomodsources)))
$(nomodobjects) : $(buildp)%.o : % $(buildp)%.dep $$(mapper_dep)
	$(due_to)
	$(ec)$(CXX) -o '$@' '$<' -c $(mapper_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(spacer)

cat_dir = $(if $(subst .,,$1),$\
  $(if $(subst .,,$2),$1/$2,$1)$\
,$\
  $(if $(subst .,,$2),$2)$\
)

# Simple Mapping - generate rules for module sources
ifneq ($(CXX_SIMPLE_MAPPING),)
  $(buildp)%.o $(cachep)%.gcm :: % $(buildp)%.dep $$(mapper_dep) | $$(call cat_dir,$$(cache_res),$$(*D))
	$(due_to)
	$(ec)$(CXX) -o '$(buildp)$*.o' '$<' -c $(mapper_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(spacer)
endif

# link all together
objects ::= $(addprefix $(buildp),$(addsuffix .o,$(sources_int)))
$(binp)$(TARGET) : $$(objects) | $(subst .,,$(bindir_res))
	$(due_to)
	$(ec)$(CXX) -o '$@' $(foreach o,$(objects),'$(o)') $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)
	$(spacer)

.PHONY : all_
all_ : $(binp)$(TARGET)

# cleanup
.PHONY : clean
clean :
	$(call echo_i,Clean...)
	$(ec)$(RM) $(verbose) '$(binp)$(TARGET)'
	$(ec)$(RM) $(verbose) *.o $(addsuffix /*.o,$(buildp)$(srcdirs_res))
	$(ec)$(RM) $(verbose) *.dep $(addsuffix /*.dep,$(buildp)$(srcdirs_res))
	$(ec)$(RM) $(verbose) *.dep~ $(addsuffix /*.dep~,$(buildp)$(srcdirs_res))
	$(ec)$(RM) $(verbose) *.ddi $(addsuffix /*.ddi,$(buildp)$(srcdirs_res))
	$(ec)$(RM) $(verbose) $(buildp)module-map.txt
ifneq ($(CXX_SIMPLE_MAPPING),)
# Simple module mapping requires a separate header cache directory.
  ifeq ($(cache_res),.)
	$(ec)$(RM) $(verbose) $(addprefix $(cachep),$(addsuffix /*.gcm,$(cmidirs)))
  else
	$(ec)LIST=; for x in $(cachep)*; do if [[ -d "$${x}" ]]; then LIST+=" $${x}"; fi; done; $(RMDIR) $(verbose) $${LIST};
  endif
	$(ec)$(RM) $(verbose) $(addprefix $(cachep),$(addsuffix /*.gcm,$(cmidirs)))
else
	$(ec)$(RM) $(verbose) $(cachep)*.gcm
endif
	$(spacer)

.PHONY : clean-header-units
clean-header-units : clean
	$(ec)$(MAKE) -f $(bin)Makefile-header-units.mk clean
	$(spacer)

.PHONY : purge
purge : clean
	$(call echo_i,Purge...)
ifneq ($(request_header_translation),)
	$(ec)$(MAKE) -f $(bin)Makefile-header-units.mk purge
endif
	$(if $(builddir_ndot),$(ec)$(RMDIR) $(verbose) $(builddir_ndot))
	$(if $(cache_ndot),$(ec)$(RMDIR) $(verbose) $(cache_ndot))
	$(spacer)

$(call info_d,END reading $(this_makefile).$(nl))
