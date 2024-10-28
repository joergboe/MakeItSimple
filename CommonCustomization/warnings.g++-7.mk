# This file contains the compiler warning definitions tailored for g++ version 7 or higher
# Copy this file to the project directory an re-name to makefile.warn
# or provide a link makefile.warn pointing to this file : ln -s ../CommonCustomization/warnings.g++-7.mk warnings.mk

cxxwarn4 = -Waligned-new=all -Walloc-zero -Wcast-align -Wconversion -Wctor-dtor-privacy -Wduplicated-cond\
  -Wfloat-conversion -Wformat=2 -Wformat-nonliteral -Wformat-security -Wformat-y2k -Winit-self -Wlogical-op\
  -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnoexcept -Wnull-dereference -Wold-style-cast -Woverloaded-virtual\
  -Wplacement-new=2 -Wredundant-decls -Wshadow=local -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel\
  -Wstrict-overflow=2 -Wstringop-overflow=3 -Wsuggest-attribute=const -Wsuggest-attribute=format\
  -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wsuggest-final-types -Wsuggest-override\
  -Wtrampolines -Wuseless-cast
cxxwarn5 = -Waggregate-return -Walloca -Warray-bounds=2 -Wcast-align -Wcast-qual -Wconditionally-supported\
  -Wdate-time -Wdisabled-optimization -Wduplicated-branches -Weffc++ -Wfloat-equal -Wformat-overflow=2\
  -Wformat-signedness -Wformat-truncation=2 -Winline -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wmultiple-inheritance -Wnamespaces -Wpacked -Wpadded\
  -Wregister -Wshadow -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wstringop-overflow=4 -Wsuggest-final-methods -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros\
  -Wvector-operation-performance -Wzero-as-null-pointer-constant
