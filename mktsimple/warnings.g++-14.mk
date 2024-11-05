# This file contains the compiler warning definitions tailored for g++ version 14 or higher

ifndef silent_mode
  $(info Using warnings.g++-14.mk)
endif

cxxwarn3 = -Wextra -Wpedantic -Wshadow=compatible-local

cxxwarn4 = -Waligned-new=all -Walloc-zero -Wcast-align -Wconversion -Wctad-maybe-unsupported -Wctor-dtor-privacy\
  -Wdeprecated-copy-dtor -Wdeprecated-enum-enum-conversion -Wdeprecated-enum-float-conversion -Wduplicated-cond\
  -Wenum-conversion -Wextra-semi -Wflex-array-member-not-at-end -Wfloat-conversion -Wformat=2 -Wformat-nonliteral\
  -Wformat-security -Wformat-y2k -Winvalid-constexpr -Winvalid-utf8 -Wlogical-op -Wmismatched-tags\
  -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wnoexcept -Wnull-dereference -Wold-style-cast\
  -Wplacement-new=2 -Wredundant-decls -Wshadow=local -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel\
  -Wstrict-overflow=2 -Wstringop-overflow=3 -Wsuggest-attribute=cold -Wsuggest-attribute=const -Wsuggest-attribute=format\
  -Wsuggest-attribute=malloc -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wsuggest-final-types\
  -Wsuggest-override -Wtemplate-id-cdtor -Wtrampolines -Wtrivial-auto-var-init -Wuseless-cast -Wvolatile

cxxwarn5 = -Waggregate-return -Walloca -Wanalyzer-symbol-too-complex -Wanalyzer-too-complex -Warith-conversion\
  -Warray-bounds=2 -Wattribute-alias=2 -Wcast-align=strict -Wcast-qual -Wcomma-subscript -Wconditionally-supported\
  -Wdate-time -Wdisabled-optimization -Wduplicated-branches -Weffc++ -Wfloat-equal -Wformat-overflow=2\
  -Wformat-signedness -Wformat-truncation=2 -Winline -Winvalid-imported-macros -Winvalid-pch -Wmissing-declarations\
  -Wmissing-include-dirs -Wmultiple-inheritance -Wnamespaces -Wnrvo -Wopenacc-parallelism -Wpacked -Wpadded\
  -Wredundant-tags -Wregister -Wshadow -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5\
  -Wstringop-overflow=4 -Wsuggest-final-methods -Wswitch-default -Wswitch-enum -Wundef -Wunused-macros\
  -Wvector-operation-performance -Wzero-as-null-pointer-constant
