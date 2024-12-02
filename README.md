# MakeItSimple - Makefiles for C++/C Projects


## Features

This github repository has a set of simple makefiles that may be useful for small or medium sized C and C++
projects without any further build system. The scripts build executable targets from c-, c++- and
assembler source files in the current project directory and create a JSON Compilation Database for
the clang language server.
These makefiles only use functions that are available in a standard GNU Linux installation and do
not require any additional build tools to be installed. They are therefore ideally suited to get a
quick introduction to the C/C++ world.

Together with an editor that can use the capabilities of the Clang language server, it is possible to
support code completion and code navigation in the best possible and interactive way.

An interactive project wizard allows a convenient and quick creation of the project skeleton for 5
different project types.

Make automatically determines which pieces of a program need to be recompiled, and issues commands
to recompile them. For maximum performance, all make scripts support parallel build.

The scripts keeps track of the last used configuration and perform a complete build, if changes in
the build configuration have been detected.

The scripts come with a comprehensive set of warning compiler options for the GNU C++ compiler and clang.
These options can be controlled in 6 levels.

All make files support 2 build modes run and debug. In build mode run an optimized executable without
debug information is built. In build mode debug the executable contains debug information.

All compiler options are valid for GNU C++ compiler and clang, if you use an alternative compiler
adapt the options and warning flags accordingly.

## Project Types

* One To One:      C++ project    - Build executable targets from each %.cpp and %.cc source file in the project directory.
* In Place Build:  C++ project    - Build one executable from all %.cpp and %.cc source files in the project directory.
* Out Place Build: C++ project   - Build one executable from all %.cpp and %.cc source files in all project source directories.
* Out Place Build: C project     - Build one executable from all %.c source files in all project source directories.
* Out Place Build: C/C++ project - Build one executable from all C++, C and assembler source files in all project source directories.

## Installation

You can execute this tool directly from the cloned/downloaded source-repository or you can install the tool.

If you want to install the tool, download the installation script of the latest release [Releases](https://github.com/joergboe/MakeItSimple/releases)
and run it. The release package is a self extracting script. Execute it and follow the instructions on the screen.
You can install the tool into an arbitrary place. The preferred way is to run this script as root user
and to install the tool into a system directory.
* The default installation place for the root user is '/usr/local'
* The default installation place for other users is '~/mktsimple'

## Quick Start

* After installation you can start the project wizard 'mktsimple' from your installation directory.
* Follow the instructions and select the option 'Create a hello world project'.
* Then open the created project directory in a shell and execute 'make all'.
* To find out more about the possible options of the tool execute 'make help'
* If the tool is not installed in the default location ('/usr/local') and the project has no local copy
of the 'warning.xxx.mk files it is necessary to add the option '-I' with the path to the include directory
of your installation e. g.: 'make -I ~/mktsimple/include'

## Samples

Samples are available in the source repository.

The directories
* OneToOne
* ProjectInPlaceBuild
* ProjectOutPlaceBuildCpp
* ProjectOutPlaceBuildC
* ProjectOutPlaceBuild
contain sample projects.

Use the following commands to complete these project fragments withe the project wizard:
    cd OneToOne; ../bin/mktsimple --project-dir . --type otocpp --noprompt --overwrite; make all
    cd ProjectInPlaceBuild; ../bin/mktsimple --project-dir . --type ipbcpp --noprompt --overwrite; make all
    cd ProjectOutPlaceBuildCpp; ../bin/mktsimple --project-dir . --type opbcpp --noprompt --overwrite; make all
    cd ProjectOutPlaceBuildC; ../bin/mktsimple --project-dir . --type opbc --noprompt --overwrite; make all
    cd ProjectOutPlaceBuild; ../bin/mktsimple --project-dir . --type opb --noprompt --overwrite; make all


If you have any suggestions or bug reports please write a Github Issue.

Learn more about MakeItSimple [here](https://www.joergboe.de/makeitsimple.html).