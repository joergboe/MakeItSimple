# MakeItSimple

This repository has a set of simple makefiles that may be useful for small- and medium-sized 
c++ projects. The makefiles are designed to use only functions that are shipped with GNU make. 
All make scripts support parallel build and ensure that the first level goals are executed in the designated order.

## Project Out Place Build

**Features**

* The [Makefile](ProjectOutPlaceBuild/Makefile) builds one executable from cpp source- and header-files in the projects source- and include-directories.
* The generated files are placed in separate directories.
* Automatic header dependencies are created.
* The list of source files and dependables is automatically created.
* The command line goals are executed in the designated order.

**Configuration**

* Change the target by changing variables BINDIR and TARGET
* The source directories of the project are stored in variable SRCDIRS
* The include directories of the project are stored in variable INCDIRS
* The warning level of the compiler is stored in CXXWARNINGS

More compiler options can be given during runtime with variables BUILD_MODE, INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS. 
(see help goal)

**Source Detection**

The cpp source files are detected in the configured list source directories SRCDIRS. This is implemented with make function 
`wildcard`. This works **not** recursive.
If you want a recursive search, you must use the following line

`CPPSOURCES := $(shell find $(SRCDIRS) -name '*.cpp')`

**Automatic Generation of Include Directory Flags**

The include flags for the include directories are generated automatically from the configured variable INCDIRS. 
You may use the following line to detect the list of the project internal include directories with:

`INCDIRS := $(shell find $(SRCDIRS) -type d)`

## Project In Place Build

**Features**

* The [Makefile](ProjectInPlaceBuild/Makefile) builds one executable from cpp source- and header-files in the project directory.
* Automatic header dependencies are created.
* The list of source files and dependables is automatically created.
* The command line goals are executed in the designated order.

**Configuration**

* Change the target by changing variable TARGET
* The warning level of the compiler is stored in CXXWARNINGS

More compiler options can be given during runtime with variables BUILD_MODE, INCLUDE_DIRS, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS. 
(see help goal)

## One To One

**Features**

* The [Makefile](OneToOne/Makefile) builds executables from each found cpp source-file.
* The list of source files and dependables is automatically created.
* The command line goals are executed in the designated order.

**Configuration**

* The warning level of the compiler is stored in CXXWARNINGS

More compiler options can be given during runtime with variables BUILD_MODE, CPPFLAGS, CXXFLAGS, LDFLAGS, TARGET_ARCH, LOADLIBES and LDLIBS. 
(see help goal)

## Make Goals

All makefiles support the following goals:
* all: default goal makes an incremental build of the target or the targets
* clean: remove all generated artifacts
* help: print an descriptive help test

The command line goals are executed in the designated order. This is also ensured when the parallel build 
(make option: -j, --jobs ) is enabled. This is especially useful for a fresh build when the goals `clean` and `all` 
are used in one make run.

## Known Problems

In the rare case that a source file has been deleted and nothing else has changed, the incremental build 
will not be triggered correctly. In such a case, you should clean the workspace.

`make clean all -j ncores`
