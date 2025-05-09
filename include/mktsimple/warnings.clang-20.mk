# This file contains the compiler warning definitions tailored for clang/clang++ version 20 or higher

cxxwarn3 = -Wextra -Wpedantic

cxxwarn4 = -Wabstract-vbase-init -Wanon-enum-enum-conversion -Warc-repeated-use-of-weak -Warray-bounds-pointer-arithmetic\
  -Wassign-enum -Watomic-properties -Wbad-function-cast -Wbinary-literal -Wbind-to-temporary-copy\
  -Wc++11-compat -Wc++11-narrowing -Wc++14-compat -Wc++17-compat -Wc++17-compat -Wc++20-compat\
  -Wcalled-once-parameter -Wcast-align -Wcast-function-type -Wclass-varargs -Wcompound-token-split\
  -Wconditional-uninitialized -Wconsumed -Wctad-maybe-unsupported\
  -Wdecls-in-multiple-modules -Wdeprecated -Wdeprecated-copy-dtor -Wdeprecated-implementations\
  -Wdocumentation -Wdtor-name\
  -Wduplicate-decl-specifier -Wduplicate-enum -Wduplicate-method-arg -Wduplicate-method-match\
  -Wexit-time-destructors -Wexpansion-to-defined -Wexplicit-ownership-type -Wextra-semi -Wextra-semi-stmt\
  -Wformat-type-confusion -Wformat=2 -Wheader-hygiene -Widiomatic-parentheses -Wimplicit-retain-self\
  -Wincompatible-function-pointer-types-strict -Wincomplete-module -Winconsistent-missing-destructor-override\
  -Winvalid-or-nonexistent-directory -Wloop-analysis -Wmain\
  -Wmissing-noreturn -Wmissing-variable-declarations\
  -Wconversion -Wnullable-to-nonnull-conversion -Wold-style-cast -Wover-aligned\
  -Woverriding-method-mismatch -Wunguarded-availability -Wperf-constraint-implies-noexcept -Wpointer-arith\
  -Wpre-c++26-compat -Wredundant-parens -Wsuggest-destructor-override -Wsuggest-override\
  -Wsuper-class-method-mismatch -Wtautological-constant-in-range-compare\
  -Wundefined-func-template -Wundefined-reinterpret-cast -Wunreachable-code-aggressive\
  -Wunsafe-buffer-usage-in-container -Wused-but-marked-unused -Wvector-conversions -Wvariadic-macro-arguments-omitted

cxxwarn5 = -Walloca -Watomic-implicit-seq-cst\
  -Wc++-compat -Wc++11-compat-pedantic -Wc++14-compat-pedantic -Wc++17-compat-pedantic -Wc++20-compat-pedantic\
  -Wcast-qual -Wcomma -Wcomments -Wcovered-switch-default -Wcstring-format-directive -Wcuda-compat\
  -Wdate-time -Wdirect-ivar-access -Wdisabled-macro-expansion -Wdocumentation-pedantic -Wdouble-promotion\
  -Wdynamic-exception-spec -Weffc++ -Wfloat-equal -Wformat-non-iso -Wformat-pedantic -Wfour-char-constants\
  -Wgcc-compat -Wglobal-constructors -Wgnu -Wimplicit-fallthrough -Wlocal-type-template-args -Wmicrosoft\
  -Wmissing-prototypes -Wnewline-eof -Wnonportable-private-system-apinotes-path -Wnonportable-system-include-path\
  -Wpacked -Wpadded -Wpoison-system-directories -Wpre-c++26-compat-pedantic -Wquoted-include-in-framework-header\
  -Wreceiver-forward-class -Wreserved-attribute-identifier -Wreserved-id-macro -Wreserved-identifier -Wreserved-user-defined-literal\
  -Rsearch-path-usage -Wshadow-all -Wshift-sign-overflow -Wsigned-enum-bitfield -Wstatic-in-inline\
  -Wstrict-prototypes -Wswitch-default -Wswitch-enum -Wthread-safety -Wthread-safety-negative -Wthread-safety-verbose\
  -Wunaligned-access -Wundef -Wundef-prefix -Wunnamed-type-template-args -Wunsafe-buffer-usage\
  -Wunsupported-dll-base-class-template\
  -Wunused-exception-parameter -Wunused-local-typedefs -Wunused-macros -Wunused-member-function -Wunused-template\
  -Wvla -Wweak-vtables -Wzero-as-null-pointer-constant

cwarn3 = $(cxxwarn3)
cwarn4 = $(cxxwarn4)
cwarn5 = $(cxxwarn5)
