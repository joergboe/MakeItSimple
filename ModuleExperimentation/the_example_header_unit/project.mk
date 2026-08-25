SOURCES ::= main.cpp src1.cpp src2.cpp
CXM_SYSTEM_HEADER_UNITS ::= iostream cstdio cstddef
CXM_SYSTEM_HEADER_UNITS += bits/stdc++.h
CXM_USER_HEADER_UNITS ::= header2.h

CXXFLAGS = -std=c++20 -fmodules

#CXM_SYSTEM_HEADER_UNITS ::= algorithm any array atomic barrier bit bitset cassert ccomplex cctype cerrno cfenv cfloat charconv chrono cinttypes climits clocale cmath codecvt compare complex complex.h concepts condition_variable coroutine csetjmp csignal cstdarg cstddef cstdint cstdio cstdlib cstring ctime cuchar cwchar cwctype cxxabi.h deque exception execution expected fenv.h filesystem flat_map flat_set format forward_list fstream functional future generator initializer_list iomanip ios iosfwd iostream istream iterator latch limits list locale map math.h memory memory_resource mutex new numbers numeric optional ostream print queue random ranges ratio regex scoped_allocator semaphore set shared_mutex source_location span spanstream sstream stack stacktrace stdatomic.h stdbit.h stdckdint.h stdexcept stdfloat stdlib.h stop_token streambuf string string_view syncstream system_error text_encoding tgmath.h thread tuple typeindex typeinfo type_traits unordered_map unordered_set utility valarray variant vector version

# Headers error free for clang++-22 and -std=c++20
#CXM_SYSTEM_HEADER_UNITS ::= algorithm any array atomic barrier bit bitset cassert ccomplex cctype cerrno cfenv cfloat charconv chrono cinttypes ciso646 climits clocale codecvt compare complex complex.h concepts condition_variable coroutine csetjmp csignal cstdalign cstdarg cstdbool cstddef cstdint cstdio cstdlib cstring ctgmath ctime cuchar cwchar cwctype cxxabi.h deque exception execution expected filesystem flat_map flat_set format forward_list fstream functional future generator initializer_list iomanip ios iosfwd iostream istream iterator latch limits list locale map math.h memory memory_resource mutex new numbers numeric optional ostream print queue random ranges ratio regex scoped_allocator semaphore set shared_mutex source_location span spanstream sstream stack stacktrace stdatomic.h stdbit.h stdckdint.h stdexcept stdfloat stdlib.h stop_token streambuf string string_view syncstream system_error text_encoding tgmath.h thread tuple typeindex typeinfo type_traits unordered_map unordered_set utility valarray variant vector version

#gcc 15 all
#CXM_SYSTEM_HEADER_UNITS ::= algorithm any array atomic barrier bit bitset cassert ccomplex cctype cerrno cfenv cfloat \
charconv chrono cinttypes ciso646 climits clocale cmath codecvt compare complex complex.h concepts condition_variable \
coroutine csetjmp csignal cstdalign cstdarg cstdbool cstddef cstdint cstdio cstdlib cstring ctgmath ctime cuchar \
cwchar cwctype cxxabi.h deque exception execution expected fenv.h filesystem flat_map flat_set format forward_list \
fstream functional future generator initializer_list iomanip ios iosfwd iostream istream iterator latch limits list \
locale map math.h memory memory_resource mutex new numbers numeric optional ostream print queue random ranges ratio \
regex scoped_allocator semaphore set shared_mutex source_location span spanstream sstream stack stacktrace stdatomic.h \
stdbit.h stdckdint.h stdexcept stdfloat stdlib.h stop_token streambuf string string_view syncstream system_error \
text_encoding tgmath.h thread tuple typeindex typeinfo type_traits unordered_map unordered_set utility valarray \
variant vector version

#gcc 16 all
#CXM_SYSTEM_HEADER_UNITS ::= algorithm any array atomic barrier bit bitset cassert ccomplex cctype cerrno cfenv cfloat \
charconv chrono cinttypes ciso646 climits clocale cmath codecvt compare complex complex.h concepts condition_variable \
contracts coroutine csetjmp csignal cstdalign cstdarg cstdbool cstddef cstdint cstdio cstdlib cstring ctgmath ctime \
cuchar cwchar cwctype cxxabi.h debugging deque exception execution expected fenv.h filesystem flat_map flat_set format \
forward_list fstream functional future generator initializer_list inplace_vector iomanip ios iosfwd iostream istream \
iterator latch limits list locale map math.h mdspan memory memory_resource meta mutex new numbers numeric optional \
ostream print queue random ranges ratio regex scoped_allocator semaphore set shared_mutex simd source_location span \
spanstream sstream stack stacktrace stdatomic.h stdbit.h stdckdint.h stdexcept stdfloat stdlib.h stop_token streambuf \
string string_view syncstream system_error text_encoding tgmath.h thread tuple typeindex typeinfo type_traits \
unordered_map unordered_set utility valarray variant vector version

# with gcc 15 the following fail
#CXM_SYSTEM_HEADER_UNITS ::= $(filter-out contracts debugging inplace_vector mdspan meta simd,$(CXM_SYSTEM_HEADER_UNITS))
