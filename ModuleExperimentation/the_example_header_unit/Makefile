# setup make it simple bin dir
ifndef MKTSIMPLE_HOME
  $(error MKTSIMPLE_HOME not set!)
endif

bin = $(MKTSIMPLE_HOME)/ModuleExperimentation/bin

mktsimple_bindir ::= $(if $(MKTSIMPLE_HOME),$(MKTSIMPLE_HOME)/bin/)

makefile ::= Makefile-mod-2sec.mk
header_makefile ::= Makefile-header-units-compact.mk

.PHONY : all
all :
	$(MAKE) -f $(bin)/$(header_makefile) all
	$(MAKE) -f $(bin)/$(makefile) all

.PHONY : clean
clean :
	$(MAKE) -f $(bin)/$(makefile) clean

.PHONY : purge
purge:
	$(MAKE) -f $(bin)/$(header_makefile) purge
	$(MAKE) -f $(bin)/$(makefile) purge

.PHONY : clean-header-units
clean-header-units : clean
	$(MAKE) -f $(bin)/$(header_makefile) clean
