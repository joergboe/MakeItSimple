# Building C++ Projects with Modules with GNU Make and GNU Compiler Collection

## Background

Modules have been introduced into C++ with the C++20 standard. C++ modules have several advantages 
over traditional preprocessor include directives; they can reduce compilation times and improve code 
hygiene. However, modules increase the demands on the build process because new dependencies for module 
import and export must be taken into account. In particular, the compiled module interface (CMI) of 
the exporting module must be available before a translation unit, that imports the module, can be 
successfully compiled. Furthermore, it is necessary to enable a mapping between the source file, the 
exported module name, and the module interface.

The following article explains one way to achieve this using the GNU Compiler Collection and GNU Make.

## The Classic Build Process

In the classic build process, without C++ modules, all translation units (TUs) are independent of 
each other and depend only on the included header files. All translation units can therefore be 
compiled independently of each other, especially in parallel. Finally, all objects are linked to an 
executable file or a library. For this, all dependencies must be made known to the make program.

In the following example, the main program `main.cpp` includes functions and so on that are defined 
in the header files `head1.h` and `head2.h`. The implementation of the functions is located in the 
translation units `src1.cpp` and `src2.cpp`, respectively. Furthermore, `src1.cpp` includes functions 
and so on from `head2.h`. This can be expressed in the following Makefile rules:

	//Makefile
	my_program: main.o src1.o src2.o
		$(CXX) -o my_program $(LINKFLAGS) main.o src1.o src2.o
	main.o: main.cpp head1.h head2.h
		$(CXX) -o main.o main.cpp -c $(CPPFLAGS) $(CXXFLAGS)
	src1.o: src1.cpp head1.h head2.h
		$(CXX) -o src1.o src1.cpp -c $(CPPFLAGS) $(CXXFLAGS)
	src2.o: src2.cpp head2.h
		$(CXX) -o src2.o src2.h -c $(CPPFLAGS) $(CXXFLAGS)

Here, `my_program` is linked from three object files, and the three object files `main.o`, `src1.o` 
and `src2.o` are created from the corresponding source files. Make ensures that non-existent or 
outdated targets are recreated and that the rules are only executed when all prerequisites are met. 
In particular, in this example, the linker is only started when all objects are complete. The source 
files can be compiled in parallel.

Compilers enable the automatic generation of the dependency tree by generating rules that describe 
the dependencies of an object file on included header files. In our example, these would be:

	//main.dep
	main.o: main.cpp head1.h head2.h

	//src1.dep
	src1.o: src1.cpp head1.h head2.h

	//src2.dep
	src2.o: src2.cpp head2.h

If, for example, only the file `src1.h` is changed, only the files `src1.o`, `main.o`, and then 
`my_program` will be rebuilt during a build run. `src2.o` will not be recompiled because none of the 
prerequisites have been changed.

A complete explanation of automatic dependency generation can be found here:
<https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/>

## The Build Process with C++ Modules

### The New Dependency Tree

When a C++ module with exports is compiled, GCC creates two files: the object file and the Compiled 
Module Interface (CMI).

If a source file (TU) with imports is compiled, the Compiled Module Interface (CMI) of the imports 
is required. If Make has the correct dependency information, the source files are compiled in the 
appropriate order.

GNU Make supports *Rules with Grouped Targets*, which indicate that a rule generates multiple target 
files. See: <https://www.gnu.org/software/make/manual/make.html#Multiple-Targets>

In the following example, the main program `main.cpp` imports functions and so on from the modules 
`module1` and `module2`. The export declarations and definitions are located in the compilation units 
`src1.cpp` and `src2.cpp`, respectively. `src1.cpp` also imports functions and so on from the module 
`module2`.

This can be expressed in the following Makefile rules:

	//Makefile
	# Link all together
	my_program: main.o src1.o src2.o
		$(CXX) -o my_program $(LINKFLAGS) main.o src1.o src2.o
	# Compile TU main with import of module1 and module2
	main.o: main.cpp module1.cmi module2.cmi
		$(CXX) -o main.o main.cpp -c -fmodules $(CPPFLAGS) $(CXXFLAGS)
	# src1 exports module1 and imports from module2
	src1.o module1.cmi &: src.cpp module2_cmi
		$(CXX) -o src1.o src1.cpp -c -fmodules $(CPPFLAGS) $(CXXFLAGS)
	# src2 exports module2
	src2.o module2.cmi &: src2.cpp
		$(CXX) -o src2.o src2.cpp -c -fmodules $(CPPFLAGS) $(CXXFLAGS)

In the classic build process, without modules, there is a fixed, predefined mapping of input and output 
file names: The source file xxx.cpp becomes the object file xxx.o. This can also be maintained in the 
module case.

GCC supports various methods for mapping CMI files, module names, and source file names. In the 
simplest case, the CMI files are stored in the `gcm.cache` directory under the module name and given 
the extension `.gcm`.

### Suggestion for Automatic Dependency Tree Generation

GCC can generate files that describe the dependency tree, similar to the classic case. The mapping 
of source files to CMI files for module exports can be done using variables.

The following dependency fragments are required for the above example:

	//main.dep
	# like in the classical case
	main.o : main.cpp
	# add prerequisites coming from module imports
	main.o : $$(CXX_MOD_CMI_module1) $$(CXX_MOD_CMI_module2)

	//src1.dep
	# the 'classical' dependencies
	src1.o gcm.cache/module1.gcm : src1.cpp
	# add prerequisites comming from module imports
	src1.o gcm.cache/module1.gcm : $$(CXX_MOD_CMI_module2)
	# module to CMI file database
	CXX_MOD_CMI_module1 = gcm.cache/module1.gcm
	# append TU to list of Module Interface Units
	CXX_MODULE_INTERFACE_UNITS += src1.cpp
	# append generated CMI file to list
	CXX_CMI_FILES += gcm.cache/module1.gcm

	//src2.dep
	src2.o gcm.cache/module2.gcm : src2.cpp
	CXX_MOD_CMI_module2 = gcm.cache/module2.gcm
	CXX_MODULE_INTERFACE_UNITS += src2.cpp
	CXX_CMI_FILES += gcm.cache/module2.gcm

In the first phase of the build process, the dependency files are created. These files are included 
in the Makefile. If the files do not exist or if their contents change, Make executes a restart before 
the second phase of the build process and ensures that the current dependency tree is used. See:
<https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles>

Since it cannot be guaranteed that the variable `CXX_MOD_CMI_<module name>` is declared before the rules 
that require it, these variables must be evaluated in the *Secondary Expansion*. To do this, the target 
`.SECONDEXPANSION` must be defined before the dependency rules.
See: <https://www.gnu.org/software/make/manual/make.html#Secondary-Expansion>

The variable containing the list of all module interface units, `CXX_MODULE_INTERFACE_UNITS`, is used 
to generate all grouped target rules for compiling the corresponding source files. Since pattern rules 
cannot use the syntax `&:`, the only remaining option is the `eval` function.

Names containing a colon are used for module partitions. Colons have a special meaning for Make. 
Therefore, colons should be replaced with single dashes `-`.

Sub-module names contain periods. Periods have no special meaning for Make and can therefore be used.

### Example Makefile

	ifndef MAKE_RESTARTS
	$(info **** Starting Makefile)
	else
	$(info **** Re-starting Makefile: number of restarts = $(MAKE_RESTARTS))
	endif

	RMDIR = rm -rf
	MKDIR = mkdir -p

	TARGET := my_program
	CXX = g++-15
	MODULFLAGS = -std=c++20 -fmodules
	CXXFLAGS ?= -Wall -Wextra -Wpedantic -ftabstop=4 -fmessage-length=0
	DEPFLAGS = -MMD -MP -MF '$*.dep.tmp' -MT '$*.o'
	OUTPUT_OPTION = -o $@

	sourcescpp := $(wildcard *.cpp)
	prepcoccpp := $(sourcescpp:.cpp=.ii)
	objectscpp := $(sourcescpp:.cpp=.o)
	depfiles := $(sourcescpp:.cpp=.dep)
	deptempfiles := $(addsuffix .tmp,$(depfiles))

	.PHONY: all
	all: $(TARGET)

	.SECONDEXPANSION:
	include $(depfiles)

	notamoduleinterface := $(filter-out $(CXX_MODULE_INTERFACE_UNITS),$(sourcescpp))
	notamoduleinterfaceobj := $(notamoduleinterface:.cpp=.o)

	$(info source files : $(sourcescpp))
	$(info object files : $(objectscpp))
	$(info depend files : $(depfiles))
	$(info CXX_MODULE_INTERFACE_UNITS files : $(CXX_MODULE_INTERFACE_UNITS))
	$(info notamoduleinterface files : $(notamoduleinterface))
	$(info )

	# Link final program
	$(TARGET): $(objectscpp)
		$(CXX) $(OUTPUT_OPTION) $(foreach var,$^,'$(var)')
		@echo -e "Finished linking: $@\n"

	# Rule for translating all non-interface files
	%.o: %.cpp
	$(notamoduleinterfaceobj): %.o : %.cpp %.dep
		$(CXX) $(OUTPUT_OPTION) $< -c $(MODULFLAGS) $(CPPFLAGS) $(CXXFLAGS)
		@echo -e "Finished compiling: $<\n"

	# Rules with Grouped Targets for module Interfaces to translate a source into object and CMI file
	define modul_template =
	$(1).o $(2) &: $(1).cpp $(1).dep | gcm.cache
		$(CXX) -o $(1).o $$< -c $(MODULFLAGS) $(CPPFLAGS) $(CXXFLAGS)
		@echo -e "Finished modul compiling: $$<\n"

	endef

	# Generate rules for all module interfaces
	$(foreach mod,$(CXX_MODULE_INTERFACE_UNITS),$(eval $(call modul_template,$(mod:.cpp=),$$(CXX_SRC_CMI_$(mod)))))

	# order only target to make the directory if not existing
	gcm.cache:
		$(MKDIR) '$@'
		@echo

	# Rule to build the dependency files
	$(depfiles): %.dep : %.cpp
		$(CXX) -o '$*.ii' $< -E $(DEPFLAGS) $(MODULFLAGS) $(CPPFLAGS) $(CXXFLAGS)
		fixdep.sh '$*.dep.tmp' '$@' '$<' '.c++-module'
		@echo -e "Finished preprocessing: $<\n"

