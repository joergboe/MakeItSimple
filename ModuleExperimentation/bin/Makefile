.DELETE_ON_ERROR:

# removing all the built-in pattern rules
MAKEFLAGS += -r

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

# include functions and variables
include $(bin)common-definitions.mk
.PHONY : $(bin)common-definitions.mk
$(if $(common-definitions),,$(error $(red)ERROR: $(bin)common-definitions.mk not included$(res)))

$(call info_d,MAKEFLAGS='$(MAKEFLAGS)')
$(call info_d,MAKECMDGOALS='$(MAKECMDGOALS)')

# default target
.PHONY : all
all :

# reading configuration from project file and figuring out bin directory, build directory and cache directory
include $(bin)build-configuration.mk
.PHONY : $(bin)build-configuration.mk
$(if $(build-configuration),,$(error $(red)ERROR: build-configuration.mk not included$(res)))

header_unit_target ::=
ifneq ($(request_header_translation),)
  header_unit_target ::= $(build_p)module-map-h.txt

#  ifndef MAKE_RESTARTS
#    $(info XX$(shell $(RM) $(verbose) $(header_unit_target)))
#  endif
endif

.PHONY : $(header_unit_target)

makefile ::= $(bin)Makefile-mod-2sec.mk
header_makefile ::= $(bin)Makefile-header-units-compact.mk

$(this_makefile) : ;

$(header_unit_target) :
	$(MAKE) -f $(header_makefile) '$@'
	$(spacer)

#$(build_ndot) :
#	$(run_tgt)
#	$(MKDIR) $(verbose) '$@'
#	$(spacer)

all : | $(header_unit_target)
	$(MAKE) -f $(makefile) all

.PHONY : clean
clean :
	$(MAKE) -f $(makefile) clean

.PHONY : purge
purge:
	$(MAKE) -f $(header_makefile) purge
	$(MAKE) -f $(makefile) purge

.PHONY : clean-header-units
clean-header-units : clean
	$(MAKE) -f $(header_makefile) clean

FORCE :: ;

$(hcache_p)% : FORCE
	$(MAKE) -f $(header_makefile) '$@'

% : FORCE | $(header_unit_target)
	$(MAKE) -f $(makefile) '$@'

$(call info_i,**** END reading $(this_makefile).$(nl))
