# MakeItSimple - Makefiles for C++ Projects



This github repository has a set of simple makefiles that may be useful for small or medium sized C++
projects without any further build system. The scripts build executable targets from c++source files
in the current project directory and create a JSON Compilation Database for the clang language server.
These makefiles only use functions that are available in a standard GNU Linux installation and do
not require any additional build tools to be installed. They are therefore ideally suited to get a
quick introduction to the C++ world.

The variant `ProjectOutPlaceBuild2` allows the linkage of C and assembler modules along with C++ source
files to the target executable.

For maximum performance, all make scripts support parallel build.

The scripts keeps track of the last used configuration and perform a complete build, if changes in
the build configuration have been detected.

The scripts come with a comprehensive set of warning compiler options for the GNU C++ compiler and clang.
These options can be controlled in 4 levels.

All make files support 2 build modes run and debug. In build mode run an optimized executable without
debug information is built. In build mode debug the executable contains debug information.

All compiler options are valid for GNU C++ compiler and clang, if you use an alternative compiler
adapt the options and warning flags accordingly.

If you have any suggestions or bug reports please write a Github Issue.

Learn more about MakeItSimple [here](https://www.joergboe.de/makeitsimple.html).