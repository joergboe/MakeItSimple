.DELETE_ON_ERROR:

# removing all the built-in pattern rules
MAKEFLAGS += -r

# Getting the path of this makefile.
this_makefile ::= $(lastword $(MAKEFILE_LIST))
bin ::= $(dir $(this_makefile))

# Include common functions and variables.
inclfile ::= $(bin)common-definitions.mk
include $(inclfile)
.PHONY : $(inclfile) # Prevent `make` from searching for an implicit rule for this file.
$(if $(common-definitions),,$(error $(red)ERROR: $(inclfile) not included$(res)))

$(if $(silent),,$(info )$(info **** $(if $(MAKE_RESTARTS),RESTART # $(MAKE_RESTARTS),START) $(this_makefile) in $(CURDIR).))

# Removing all the built-in pattern rules.
MAKEFLAGS += -r
$(call info_d,MAKEFLAGS='$(MAKEFLAGS)')
$(call info_d,MAKECMDGOALS='$(MAKECMDGOALS)')

# Place the default target before any before including any user defined project files.
.PHONY : all
all :

.DELETE_ON_ERROR:

# Prevent `make` from searching for an implicit rule for this file.
.PHONY : $(this_makefile)

# Reading configuration from project file and figure out bin directory, build directory and cache directory.
inclfile ::= $(bin)build-configuration.mk
include $(inclfile)
.PHONY : $(inclfile)
$(if $(build-configuration),,$(error $(red)ERROR: build-configuration.mk not included$(res)))

header_unit_target ::=
ifneq ($(request_header_translation),)
  header_unit_target ::= $(build_p)module-map-h.txt
endif
.PHONY : $(header_unit_target)

makefile ::= $(bin)Makefile-mod-2sec.mk
header_makefile ::= $(bin)Makefile-header-units-compact.mk

$(header_unit_target) : $(build_ndot)
	$(MAKE) -f $(header_makefile) '$@'
	$(spacer)

$(build_ndot) :
	$(run_tgt)
	$(MKDIR) $(verbose) '$@'
	$(spacer)

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
