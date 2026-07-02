export module B;

export import B_impl;
import A_impl;

export typedef Struct_B_impl<typename Struct_A_impl> B;
