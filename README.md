# MakeItSimple - Makefiles for C++/C Projects


## Features

This github repository has a set of simple makefiles that may be useful for small or medium sized C++
projects without any further build system. The scripts build executable targets from c++source files
in the current project directory and create a JSON Compilation Database for the clang language server.
These makefiles only use functions that are available in a standard GNU Linux installation and do
not require any additional build tools to be installed. They are therefore ideally suited to get a
quick introduction to the C++ world.

An interactive project wizard allows a convenient and quick creation of the project skeleton for 5
different project types.

For maximum performance, all make scripts support parallel build.

The scripts keeps track of the last used configuration and perform a complete build, if changes in
the build configuration have been detected.

The scripts come with a comprehensive set of warning compiler options for the GNU C++ compiler and clang.
These options can be controlled in 6 levels.

All make files support 2 build modes run and debug. In build mode run an optimized executable without
debug information is built. In build mode debug the executable contains debug information.

All compiler options are valid for GNU C++ compiler and clang, if you use an alternative compiler
adapt the options and warning flags accordingly.

## Project Types

* One To One:     C++ project    - Build executable targets from each %.cpp and %.cc source file in the project directory.
* In Place Build: C++ project    - Build one executable from all %.cpp and %.cc source files in the project directory.
* Out Place Build: C++ project   - Build one executable from all %.cpp and %.cc source files in all project source directories.
* Out Place Build: C project     - Build one executable from all %.c source files in all project source directories.
* Out Place Build: C/C++ project - Build one executable from all C++, C and assembler source files in all project source directories.

## Installation

The release package is a self extracting script. Execute it and follow the instructions.
You can install the tool into an arbitrary palace. If you want to install the tool into a system
directory execute the installation script as root.
* The default installation place for the root user is '/usr/local'
* The default installation place or other users is '~/mktsimple'

It is recommended to enter the location of the test framework into your PATH like:

## Quick Start

* After installation you can start the project wizard	'mktsimple' from your installation directory.
* Follow the instructions from the screen and select the option 'Create a hello world project'.
* Then open the created project directory and execute 'make all'.

If you have any suggestions or bug reports please write a Github Issue.

Learn more about MakeItSimple [here](https://www.joergboe.de/makeitsimple.html).