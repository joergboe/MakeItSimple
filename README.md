# MakeItSimple - Makefiles for C++ Projects



This github repository has a set of simple makefiles that may be useful for small or experimental C++ projects without any further build system. These makefiles only use functions that are available in a standard GNU Linux installation and do not require any additional build tools to be installed. They are therefore ideally suited to get a quick introduction to the C++ world.

For maximum performance, all make scripts support parallel build and ensure that the first level goals are executed in the designated order.

The scripts come with a comprehensive set of warning compiler options for the GNU C++ compiler (g++). These options can be controlled in 4 levels.

All make files support 2 build modes run and debug. In build mode run an optimized executable without debug information is built. In build mode debug the executable contains debug information.

All compiler options are valid for GNU C++ compiler, if you use an alternative compiler adapt the options and warning flags accordingly.

If you have any suggestions or bug reports please write a Github Issue or join the discussion.

Learn more about MakeItSimple [here](https://www.joergboe.de/makeitsimple.html).