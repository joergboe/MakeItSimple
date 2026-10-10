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

# getting path of this makefile
this_makefile ::= $(lastword $(MAKEFILE_LIST))
bin ::= $(dir $(this_makefile))

# checking command-line option -s
single_make_options ::= $(firstword -$(MAKEFLAGS))
silent =
ifeq (s,$(findstring s,$(single_make_options)))
  silent = 1
endif

# intro
$(if $(silent),,$(info )$(info **** $(if $(MAKE_RESTARTS),RESTART # $(MAKE_RESTARTS),START) $(this_makefile) in $(CURDIR).))

keep_going =
ifeq (k,$(findstring k,$(single_make_options)))
  keep_going = 1
endif

# include functions and variables
include $(bin)definitions.mk
# do not try update definitions.mk
.PHONY : $(bin)definitions.mk
$(if $(definitions),,$(error $(red)ERROR: $(bin)definitions.mk not included$(res)))

# remove all the built-in pattern rules
MAKEFLAGS += -r

# global settings
SHELL = /bin/bash
.SHELLFLAGS ::= -ec
RMDIR = rm -rf
MKDIR = mkdir
RM = rm -f
.DELETE_ON_ERROR:

# Place the default target before any before including any user defined project files.
.PHONY : all
all : all_

# a dummy rule to update this makefile
$(bin)Makefile-mod-2sec.mk : ;

# checking goals
cleanup_goals = clean purge clean-header-units info
goals ::= $(MAKECMDGOALS)
# The variable cleanup is also used to prevent inclusion of dependent makefiles.
cleanup ::= $(filter $(cleanup_goals),$(goals))
ifneq ($(cleanup),)
  ifneq (,$(filter-out $(cleanup_goals),$(goals)))
    $(error $(red)ERROR: The goals '$(cleanup_goals)' must not be used in conjunction with other targets.$(res))
  endif
endif

# reading configuration from project file and figure out bin directory, build directory and cache directory
include $(bin)segment-build-configuration.mk
.PHONY : $(bin)segment-build-configuration.mk
$(if $(segment-build-configuration),,$(error $(red)ERROR: segment-build-configuration.mk not included$(res)))

# checking cache directory
ifneq ($(CXX_SIMPLE_MAPPING),)
  $(if $(and $(mcache_p),$(build_p)),,$(error $(red)ERROR: If simple mapping is used, build directory and module cache\
                                     directory must not be the dot directory!\
                                     see: <https://savannah.gnu.org/bugs/?68714>$(res)))
endif

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

# get_path_to_level_zero - returns the path n times $(name)/ where n is the number of leading .. components in $(path)
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

# get the last path component from the current project directory as target name
TARGET ?= $(lastword $(subst /, ,$(CURDIR)))
$(call info_i,Build target '$(build_p)$(TARGET)'$(nl))

# The target is now known, we can implement the all_ target.
.PHONY : all_
all_ : $(build_p)$(TARGET)

# linking all together
objects ::= $(addprefix $(bbd_p),$(addsuffix .o,$(sources)))
$(call info_d,objects = '$(objects)')
$(build_p)$(TARGET) : $(objects) | $(build_ndot)
	$(due_to)
	$(CXX) -o '$@' $(foreach o,$(objects),'$(o)') $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)
	$(call echo_i,All done.)
	$(spacer)

# trigger dependent targets
FORCE :: ;

# make header unit cmi files - must run once for productive goals at start up
header_unit_target ::=
ifndef MAKE_RESTARTS
  ifneq ($(request_header_translation),)
    header_unit_target ::= $(build_p)module-map-h.modm

    $(header_unit_target) : FORCE | $(build_ndot)
	@$(MAKE) -f $(bin)Makefile-header-units.mk '$@'
	$(spacer)
  endif
endif

# required compiler options
infoflags =
ifneq ($(verbose),)
  infoflags = -flang-info-include-translate -flang-info-module-cmi
endif

# header mapper option for depfiles
hmap_opt ::= $(if $(and $(user_mapping),$(request_header_translation)),-fmodule-mapper=$(build_p)module-map-h.modm)

# rule to generate dependency files
# The defile rules have direct dependencies to imported module unit files,thus a update of the module-map-h.modm
# timestamp should not trigger the depfile rule. So there is no dependency to the module-map-h.modm required.
depfiles ::= $(addprefix $(bbd_p),$(addsuffix .dep,$(sources)))
$(call info_d,depfiles = '$(depfiles)')
$(depfiles) : $(bbd_p)%.dep : % | $(header_unit_target)
	$(due_to)
	$(CXX) '$<' -MM -MF '$@' -MQ '$@' $(hmap_opt) -fdeps-format=p1689r5 -fdeps-file='$(bbd_p)$*.ddi' -fdeps-target='$(bbd_p)$*.o' -c $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(bin)p1689_to_make_sec.sh '$(bbd_p)$*.ddi' '$@' '$(bbd_p)$*.o' '$<'
	$(spacer)

.PHONY : depend
depend : $(depfiles)
	$(call echo_i,Dependency files are up to date.)
	$(spacer)

.SECONDEXPANSION :

# appending directory prerequisites to depfile rules
$(depfiles) : $(bbd_p)%.dep : | $$(if $$(call neq,$$(@D),.),$$(@D))

# get_cmi_name - map module name or source file name to the cmi file name for project modules
# input: 1 - module name
#        2 - source file name
ifeq ($(CXX_SIMPLE_MAPPING),)
  get_cmi_name = $(mcbd_p)$(subst :,-,$1).gcm
else
  get_cmi_name = $(mcbd_p)$2.gcm
endif

# mapper file dependency
# The object file rules have direct dependencies to imported module unit files and module cmi files,thus a
# update of the 'module-map-h.modm' timestamp should not trigger the this rules.
# However if the external module mapper file has changed, total different cmi files may come into play.
# So there is dependency to the 'module-map-ext.modm' required.
map_dep ::= $(external_module_map)

# mapper option
map_opt ::= $(if $(user_mapping),-fmodule-mapper=$(build_p)module-map.modm)

# All object files have the map_target as Order Only Prerequisite.
map_target ::= $(if $(user_mapping),$(build_p)module-map.modm)

# include all depfiles with provided modules database: CXX_SRC_MOD_IF_LIST
# depfiles require get_cmi_name function
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
  $(call info_i,generate module rule $(obj) $(cmi) &: $(src) $(dep) $(map_dep) | $(map_target) $(mcbd_ndot))

  $$(obj) $$(cmi) : my_obj ::= $$(obj)
  $$(obj) $$(cmi) &: $$(subst $$$$,$$$$$$$$,$$(src) $$(dep)) $$$$(map_dep) | $$$$(map_target) $$$$(mcbd_ndot)
	$$(due_to)
	$$(CXX) -o '$$(my_obj)' '$$<' -c $$(map_opt) $$(CXXFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) $$(infoflags)
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
modsources ::=
nomodsources ::=
modulemap ::=
ifeq ($(strip $(CXX_SRC_MOD_IF_LIST)),)
  $(call info_i,No module database!)
endif
$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
  $(let src mod is_if,$(subst ;, ,$(line)),\
    $(if $(subst -,,$(mod)),\
      $(let modi cmi obj dep,$(subst :,-,$(mod)) $(call get_cmi_name,$(mod),$(src)) $(bbd_p)$(src).o $(bbd_p)$(src).dep,\
        $(if $(CXX_MOD_$(modi)_CMI),\
          $(if $(keep_going),\
            $(warning $(yel)WARNING: Duplicate module $(mod) in source unit $(src)$(res))\
          ,\
            $(error $(red)ERROR: Duplicate module $(mod) in source unit $(src)$(red))\
          )\
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
$(call info_i,modsources = '$(modsources)')
$(call info_i,nomodsources = '$(nomodsources)')

# generate rules for no module sources
nomodobjects ::= $(addprefix $(bbd_p),$(addsuffix .o,$(nomodsources)))
$(call info_d,nomodobjects = '$(nomodobjects)')
$(nomodobjects) : $(bbd_p)%.o : % $(subst $$,$$$$,$(bbd_p))%.dep $$(map_dep) | $(map_target)
	$(due_to)
	$(CXX) -o '$@' '$<' -c $(map_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(spacer)

# Simple Mapping - generate rules for module sources
ifneq ($(CXX_SIMPLE_MAPPING),)
  $(bbd_p)%.o $(mcbd_p)%.gcm : % $(subst $$,$$$$,$(bbd_p))%.dep $$(map_dep) | $(map_target) $$(call cat_dir,$$(mcbd),$$(*D))
	$(due_to)
	$(CXX) -o '$(bbd_p)$*.o' '$<' -c $(map_opt) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) $(infoflags)
	$(spacer)
endif

# write module-map
# NOTE: trailing spaces are not allowed
ifeq ($(cleanup),)
  map_new ::= $(subst ;, ,$(subst $(space),$(nl),$(modulemap)))
  map_old ::= $(file < $(build_p)module-map-m.txt)
  $(call info_d,map_new = '$(map_new)')
  $(call info_d,map_old = '$(map_old)')
  ifneq ($(map_old),$(map_new))
    $(call info_i,Write module map modules part '$(build_p)module-map-m.txt'.)
    $(file > $(build_p)module-map-m.txt,$(map_new))
  else
    $(call info_i,Module map modules part is up do date.)
  endif
endif

# header mapper dependency
hmap_dep ::= $(if $(and $(user_mapping),$(request_header_translation)),$(build_p)module-map-h.modm)
$(call info_d,hmap_dep = '$(hmap_dep)')

$(map_target) : $(buildp)module-map-m.tmp $(hmap_dep) $(external_module_map)
	$(due_to)
	$(ec)echo '$$root ' > '$@'
	$(if $(hmap_dep),$(ec)grep --invert-match '$root' $(buildp)module-map-m.tmp >> '$@')
	$(if $(external_module_map),$(ec)grep --invert-match $(external_module_map) >> '$@')
	$(spacer)

$(call info_d,)

# creating all build directories
ifneq ($(bbd),.)
  all_build_dirs ::= $(bbd_ndot) $(addprefix $(bbd_p),$(buildsub_ndot))
  $(call info_d,all_build_dirs = '$(all_build_dirs)')
  # the unique list of directory parts with trailing slash removed
  all_build_dir_parts ::= $(patsubst %/,%,$(sort $(foreach path,$(all_build_dirs),$(call all_dirs,$(path)/))))
  $(call info_d,all_build_dir_parts = '$(all_build_dir_parts)')

  $(all_build_dir_parts) : % : | $$(@D)
	$(run_tgt)
	$(if $(patsubst %..,,$@),$(MKDIR) $(verbose) '$@')
	$(spacer)
else
  $(call info_d,Storing build files in source directories.)
endif

# creating all cmi directories
ifneq ($(mcbd),.)
  ifneq ($(bbd),$(mcbd))
    all_cmi_dirs ::= $(mcbd_ndot) $(addprefix $(mcbd_p),$(cmisub_ndot))
    $(call info_d,all_cmi_dirs = '$(all_cmi_dirs)')

    all_cmi_dir_parts ::= $(patsubst %/,%,$(sort $(foreach path,$(all_cmi_dirs),$(call all_dirs,$(path)/))))
    $(call info_d,all_cmi_dir_parts = '$(all_cmi_dir_parts)')

    $(all_cmi_dir_parts) : % : | $$(@D)
	$(run_tgt)
	$(if $(patsubst %..,,$@),$(MKDIR) $(verbose) '$@')
	$(spacer)
  else
    $(call info_d,Storing cmi files in build directories.)
  endif
else
  $(call info_d,Storing cmi files in source directories.)
endif

# cleanup
.PHONY : clean
clean :
	$(call echo_i,Cleanup...)
	$(RM) $(verbose) '$(build_p)$(TARGET)'
	$(RM) $(verbose) $(addprefix $(bbd_p),$(addsuffix /*.o,$(buildsub)))
	$(RM) $(verbose) $(addprefix $(bbd_p),$(addsuffix /*.dep,$(buildsub)))
	$(RM) $(verbose) $(addprefix $(bbd_p),$(addsuffix /*.dep~,$(buildsub)))
	$(RM) $(verbose) $(addprefix $(bbd_p),$(addsuffix /*.ddi,$(buildsub)))
	$(RM) $(verbose) $(build_p)module-map.modm $(build_p)module-map-m.txt
ifneq ($(CXX_SIMPLE_MAPPING),)
  # Simple module mapping requires a separate header cache directory.
  # This recipe may delete header cmi files, thus separate header cache is preferred.
	$(RM) $(verbose) $(addprefix $(mcbd_p),$(addsuffix /*.gcm,$(cmisub)))
else
	$(RM) $(verbose) $(mcbd_p)*.gcm
endif
	$(spacer)

.PHONY : clean-header-units
clean-header-units : clean
	@$(MAKE) -f $(bin)Makefile-header-units.mk clean
	$(spacer)

.PHONY : purge
purge : clean
	$(call echo_i,Purge...)
ifneq ($(request_header_translation),)
	@$(MAKE) -f $(bin)Makefile-header-units.mk purge
endif
	$(RMDIR) $(verbose) $(build_ndot) $(mcache_ndot)
	$(spacer)

.PHONY : info
info : ;

$(call info_i,**** END reading $(this_makefile).$(nl))
