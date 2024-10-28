# This file contains the compiler warning definitions tailored for g++ version 12 or higher
# Copy this file to the project directory an re-name to makefile.warn
# or provide a link makefile.warn pointing to this file : ln -s ../CommonCustomization/warnings.g++-12.mk warnings.mk

cxxwarn4 = -Waligned-new=all -Walloc-zero -Wcast-align -Wconversion -Wctad-maybe-unsupported -Wctor-dtor-privacy\
  -Wdeprecated-copy-dtor -Wdeprecated-enum-enum-conversion -Wdeprecated-enum-float-conversion -Wduplicated-cond\
  -Wenum-conversion -Wextra-semi -Wfloat-conversion -Wformat=2 -Wformat-nonliteral\
  -Wformat-security -Wformat-y2k -Wlogical-op -Wmismatched-tags\
  -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnoexcept -Wnull-dereference -Wold-style-cast\
  -Wplacement-new=2 -Wredundant-decls -Wshadow=local -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel\
  -Wstrict-overflow=2 -Wstringop-overflow=3 -Wsuggest-attribute=cold -Wsuggest-attribute=const -Wsuggest-attribute=format\
  -Wsuggest-attribute=malloc -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wsuggest-final-types\
  -Wsuggest-override -Wtrampolines -Wtrivial-auto-var-init -Wuseless-cast -Wvolatile
cxxwarn5 = -Waggregate-return -Walloca -Wanalyzer-too-complex -Warith-conversion\
  -Warray-bounds=2 -Wattribute-alias=2 -Wcast-align=strict -Wcast-qual -Wcomma-subscript -Wconditionally-supported\
  -Wdate-time -Wdisabled-optimization -Wduplicated-branches -Weffc++ -Wfloat-equal -Wformat-overflow=2\
  -Wformat-signedness -Wformat-truncation=2 -Winline -Winvalid-imported-macros -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wmultiple-inheritance -Wnamespaces -Wopenacc-parallelism -Wpacked -Wpadded\
  -Wredundant-tags -Wregister -Wshadow -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wstringop-overflow=4 -Wsuggest-final-methods -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros\
  -Wvector-operation-performance -Wzero-as-null-pointer-constant

cwarn4 = -Walloc-zero -Wcast-align -Wconversion\
  -Wduplicated-cond\
  -Wenum-conversion -Wfloat-conversion -Wformat=2 -Wformat-nonliteral\
  -Wformat-security -Wformat-y2k -Wlogical-op\
  -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnull-dereference\
  -Wredundant-decls -Wshadow=local -Wsign-conversion\
  -Wstrict-overflow=2 -Wstringop-overflow=3 -Wsuggest-attribute=cold -Wsuggest-attribute=const -Wsuggest-attribute=format\
  -Wsuggest-attribute=malloc -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wsuggest-final-types\
  -Wtrampolines -Wtrivial-auto-var-init
cwarn5 = -Waggregate-return -Walloca -Wanalyzer-too-complex -Warith-conversion\
  -Warray-bounds=2 -Wattribute-alias=2 -Wcast-align=strict -Wcast-qual\
  -Wdate-time -Wdisabled-optimization -Wduplicated-branches -Wfloat-equal -Wformat-overflow=2\
  -Wformat-signedness -Wformat-truncation=2 -Winline -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wopenacc-parallelism -Wpacked -Wpadded\
  -Wshadow -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wstringop-overflow=4 -Wsuggest-final-methods -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros\
  -Wvector-operation-performance
