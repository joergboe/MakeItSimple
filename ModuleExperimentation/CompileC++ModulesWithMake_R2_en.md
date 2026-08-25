# Building C++ Projects with Modules with GNU Make and GNU Compiler Collection

## Background

With the C++20 standard, modules were introduced to C++. C++ modules offer several 
advantages over the preprocessor's traditional include directives; they can reduce 
compilation times and improve code hygiene. However, modules increase the demands 
on the build process because new dependencies for module import and export must 
be considered. In particular, the compiled module interface (CMI) of the exporting 
module must be available before a compilation unit that imports the module can be 
successfully compiled. Furthermore, it is necessary to establish a mapping between 
the source file, module name, and module interface file.

The following article explains one way to achieve this using the GNU Compiler 
Collection and GNU Make.


## The Classic Build Process

In the classic build process without C++ modules, all translation units (TUs) are 
independent of each other and depend only on the included header files. All 
translation units can therefore be compiled independently of each other, especially 
in parallel. Finally, all objects are linked to form an executable file or a 
library.

During the development process, a project typically needs to be compiled very 
frequently. It is common practice for a build system to recompile only those 
translation units to which modified files contribute. For this to work, the make 
program must be informed of all dependencies.

In the following example, the main program `main.cpp` includes functions, etc., 
that are defined in the header files `head1.h` and `head2.h`. The implementation 
of these functions is located in the translation units `src1.cpp` and `src2.cpp`, 
respectively. Furthermore, `src1.cpp` includes functions etc. from `head2.h`. 
This can be expressed in the following Makefile rules:

	//Makefile1.mk
	my_program : main.o src1.o src2.o
		g++ -o my_program main.o src1.o src2.o
	main.o : main.cpp head1.h head2.h
		g++ -o main.o main.cpp -c
	src1.o : src1.cpp head1.h head2.h
		g++ -o src1.o src1.cpp -c
	src2.o : src2.cpp head2.h
		g++ -o src2.o src2.cpp -c

Here, the program `my_program` is linked from three object files, and the three 
object files `main.o`, `src1.o`, and `src2.o` are created from the corresponding 
source files. `Make` ensures that non-existent or outdated targets are recreated 
and that rules are only executed when all prerequisites are finished. Specifically, 
in this example, the linker is started once all objects are complete. The 
compilation of all source files can be performed in parallel.

Compilers enable the automatic generation of the dependency tree by creating 
rules that describe the dependencies of an object file on the source file and on 
included header files.

In our example, these are:

	//main.dep
	main.o : main.cpp head1.h head2.h

	//src1.dep
	src1.o : src1.cpp head1.h head2.h

	//src2.dep
	src2.o : src2.cpp head2.h

If, for example, only the file `head1.h` is changed, during a build run only the 
files `src1.o`, `main.o` and then `my_program` will be rebuilt; `src2.o` will not 
be recompiled, since none of the prerequisites have been changed.

A full explanation of automatic dependency creation can be found here: 
<https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/>

For compilation, there is usually a fixed, predefined mapping of input and output 
filenames: e.g., the source file foo.cpp becomes the object file foo.o.

Therefore, the rules for compilation can be formulated as implicit rules or static 
pattern rules (see: <https://www.gnu.org/software/make/manual/html_node/Static-Pattern.html>).

The simplified Makefile:

	//Makefile2.mk
	objects = main.o src1.o src2.o

	my_program : $(objects)
		g++ -o my_program $^

	$(objects) : %.o: %.cpp
		g++ -o $@ $< -c -MMD -MF $*.dep

	depfiles = $(objects:.o=.dep)
	-include $(depfiles)


## The Build Process with C++ Modules

### The New Dependency Tree

When a C++ module that exports functions, variables, etc., is compiled, GCC 
generates two output files: the object file and the compiled module interface (CMI).

GCC supports various methods for mapping the CMI file to the module name and the 
source file name. In the simplest case, the CMI files are placed in the `gcm.cache` 
directory under the module name and given the `.gcm` extension.

The fixed, predefined mapping of source and object file names can also be 
maintained in the module case.

When a source file is compiled that imports items from another module, the 
compiled module interface (CMI) of the imports is required. If `make` has the 
correct dependency data, the source files are compiled in the appropriate order.

GNU Make supports grouped target rules, which express that a recipe produces 
multiple output files. 
See: <https://www.gnu.org/software/make/manual/make.html#Multiple-Targets>

In the following example, the main program `main.cpp` imports functions, etc., 
from the modules `module1` and `module2`. The export declarations and definitions 
are located in the translation units `src1.cpp` and `src2.cpp`, respectively. 
Additionally, `src1.cpp` imports functions, etc., from module `module2`.

Furthermore, the source files include constants from the header files `header1.h` 
and `header2.h`.

The rules for translating the source files and for the linker might look like 
this:

	//Makefile1.mk
	my_program: main.o src1.o src2.o
		g++ -o my_program main.o src1.o src2.o

	main.o: main.cpp header2.h gcm.cache/module1.gcm gcm.cache/module2.gcm
		g++ -o main.o main.cpp -c -fmodules

	src1.o gcm.cache/module1.gcm &: src1.cpp header1.h gcm.cache/module2.gcm
		g++ -o src1.o src1.cpp -c -fmodules

	src2.o gcm.cache/module2.gcm &: src2.cpp header2.h
		g++ -o src2.o src2.cpp -c -fmodules

The standard does not allow circular module imports. Make issues a warning if a 
circularity is detected in the dependency tree and terminates the dependency 
analysis.

### The Automatic Generation of Dependency Rules

GCC can generate files that describe the dependency tree, similar to the classic 
case.

In addition to the usual header dependencies, the generated dependency files must 
contain dependencies on the CMI files of the imported modules. The location of the 
CMI files can vary, so this dependency is expressed as a variable of the form 
`CXX_MOD_<module name>_CMI`. The value of the variable is determined in the make 
script.

Module partition names contain a colon. Colons have a special meaning for Make 
and cannot be used in variable names. Therefore, colons must be replaced with 
dashes (`-`). All other characters that can be used in C++ module names, including 
characters from the extended character set, are allowed in Make variable names. 
A dollar sign (`$`) must be represented by two or four consecutive dollar signs, 
respectively.

Submodule names contain periods. Periods have no special meaning for Make and can 
be used in variable names.

Furthermore, the dependency files must provide information that allows the module 
name to be deduced from the source filename. This is achieved by creating a list 
containing a triple for each module source: the source filename, the module name, 
and a Boolean value 'is_interface' (`CXX_SRC_MOD_IF_LIST`). The parts of the 
triple are separated by semicolons. A semicolon must not appear in either a module 
or a filename. Similarly, a colon in the module name must be replaced with a single 
bar, and the dollar sign must be replaced with two dollar signs.

Since it cannot be guaranteed that the declarations of the variables 
`CXX_MOD_<module name>_CMI` occur before the rules that require them, these 
variables must be evaluated in the Secondary Expansion. For this purpose, the 
target `.SECONDEXPANSION` must be defined before the dependency rules.

See: <https://www.gnu.org/software/make/manual/make.html#Secondary-Expansion>

The dependency rules for the example are:

	//main.dep
	main.o : main.cpp header2.h
	main.o : $$(CXX_MOD_module1_CMI) $$(CXX_MOD_module2_CMI)

	//src1.dep
	src1.o : src1.cpp header1.h
	src1.o : $$(CXX_MOD_module2_CMI)
	CXX_SRC_MOD_IF_LIST += src1.cpp;module1;1

	//src2.dep
	src2.o : src2.cpp header2.h
	CXX_SRC_MOD_IF_LIST += src2.cpp;module2;1

	//automatic generated definitions
	CXX_MOD_module1_CMI = gcm.cache/module1.gcm
	CXX_MOD_module2_CMI = gcm.cache/module2.gcm
	modsources = src1.cpp src2.cpp

The prerequisites are listed only for the object files. Since a grouped target 
rule is used for producing the module objects, Make recognizes that the module 
object and the CMI file are created simultaneously.

The generated dependency files are then included.

Make always attempts to execute the rules that update the Makefile or the included 
files 'main.dep', 'src1.dep', or 'src2.dep' first.

See: <https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles>

This is how the dependency files are created in the first phase of the build 
process. If the content of the included files changes, Make restarts before the 
second phase of the build process, ensuring that the current dependency tree is 
always used.

The Make script:

	//Makefile3.mk
	sources = main.cpp src1.cpp src2.cpp
	objects = $(sources:.cpp=.o)

	# Link all together
	my_program: $(objects)
		g++ -o my_program $(objects) -std=c++20 -fmodules

	# generate dependency files
	depfiles = $(sources:.cpp=.dep)
	$(depfiles) : %.dep: %.cpp
		g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
		p1689_to_make2.sh $*.ddi $< $*.o $@

	# Include all depfiles
	.SECONDEXPANSION:
	include $(depfiles)

The rule for generating the dependency file performs the following steps:

1. The target of this rule is the dependency file (.dep) itself. This ensures 
that the dependency file is recreated if it does not exist or if the source file 
or one of the included header files is newer than the target. 
(`-MM -MF $@ -MQ $@`)

2. The module dependencies are stored in a JSON-encoded file (.ddi). 
(`-fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o`)

3. The script `p1689_to_make2.sh` reads the .ddi file and appends the module 
dependencies in Make format to the .dep file.


### The Automated Generation of Production Rules

The rules for compiling module units differ from the rules for ordinary source 
files. Since the relationship between source filename and module name cannot be 
established through pattern substitution, no pattern rules can be used for module 
units. Here, grouped target rules are generated by the `eval` function in a loop.

The list `CXX_SRC_MOD_IF_LIST` is used to generate all grouped target rules for 
translating the module files and to resolve the link between module name and CMI 
file. If a specific mapping of the CMI files is desired, it can be implemented 
here. The example uses the default mapping.

	//Makefile3.mk
	define modul_rule_template
	$(src:.cpp=.o) gcm.cache/$(mod).gcm &: $(src:.cpp=.dep)
		g++ -o $(src:.cpp=.o) $(src) -c -std=c++20 -fmodules
	endef

	$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
		$(let src mod is_if,$(subst ;, ,$(line)),\
			$(eval $(modul_rule_template))\
			$(eval CXX_MOD_$(mod)_CMI = gcm.cache/$(mod).gcm)\
			$(eval modsources += $(src))\
		)\
	)

As a prerequisite for an object file, the corresponding dependency file is 
specified. This transfers all header dependencies of the dependency file to the 
object file.

In a grouped targets rule, Make combines the dependency trees of all targets and 
ensures that the targets are recreated if any prerequisite of any target is newer 
than the oldest target in the rule.

Rules for ordinary source files can be formulated as before, either as an 
implicit rule or as a Static Pattern Rule.

	//Makefile3.mk
	# no module sources
	nomodsources = $(filter-out $(modsources),$(sources))
	nomodobjects = $(nomodsources:.cpp=.o)

	$(nomodobjects): %.o: %.cpp %.dep
		g++ -o $@ $< -c -std=c++20 -fmodules

### Header Units

If a translation unit imports Header Units, the Compiled Header Interface must 
be available before the dependency file can be generated. Therefore, all Header 
Units must be translated in a preceding step.
