# This file contains the compiler warning definitions tailored for g++ version 7 or higher
# Copy this file to the project directory an re-name to makefile.warn
# or provide a link makefile.warn pointing to this file : ln -s ../CommonCustomization/warnings.g++7.mk warnings.mk

cxxwarn2 = -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wformat=2 -Winit-self -Wlogical-op -Wmissing-declarations \
-Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wconversion \
-Wsign-conversion -Wstrict-null-sentinel -Wundef -Wfloat-equal -Winline -Wzero-as-null-pointer-constant \
-Wuseless-cast -Wstrict-overflow=4 -Wduplicated-branches -Wduplicated-cond -Wdate-time \
-Wnull-dereference -Wno-aggressive-loop-optimizations -Wdisabled-optimization
