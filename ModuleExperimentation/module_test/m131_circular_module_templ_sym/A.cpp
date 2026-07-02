export module A;

export import A_impl;
import B_impl;

export typedef Struct_A_impl<typename Struct_B_impl<Struct_A_impl> > A;
