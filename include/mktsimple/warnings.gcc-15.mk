# This file contains the compiler warning definitions tailored for gcc version 15 or higher

cwarn3 = -Wextra -Wpedantic -Wshadow=compatible-local

cwarn4 = -Walloc-zero -Wcast-align -Wconversion\
  -Wduplicated-cond\
  -Wenum-conversion -Wflex-array-member-not-at-end -Wfloat-conversion -Wformat=2 -Wformat-nonliteral\
  -Wformat-security -Wformat-y2k -Winvalid-utf8 -Wlogical-op\
  -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnull-dereference\
  -Wredundant-decls -Wshadow=local -Wsign-conversion\
  -Wstrict-overflow=2 -Wstringop-overflow=3 -Wsuggest-attribute=cold -Wsuggest-attribute=const -Wsuggest-attribute=format\
  -Wsuggest-attribute=malloc -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wsuggest-final-types\
  -Wtrampolines -Wtrivial-auto-var-init -Wuseless-cast

cwarn5 = -Waggregate-return -Walloca -Wanalyzer-symbol-too-complex -Wanalyzer-too-complex -Warith-conversion\
  -Warray-bounds=2 -Wattribute-alias=2 -Wc11-c23-compat -Wcast-align=strict -Wcast-qual\
  -Wdate-time -Wdisabled-optimization -Wduplicated-branches -Wfloat-equal -Wformat-overflow=2\
  -Wformat-signedness -Wformat-truncation=2 -Winline -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wopenacc-parallelism -Wpacked -Wpadded\
  -Wshadow -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wstringop-overflow=4 -Wsuggest-final-methods -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros\
  -Wvector-operation-performance
