/*
 * Primary Module Interface Unit
*/

/* A module can have module partition units. They are module units whose module declarations include
 * a module partition, which starts with a colon : and is placed after the module name.
 * 
 * A module partition represents exactly one module unit (two module units cannot designate the same
 * module partition).
 * They are visible only from inside the named module
 * (translation units outside the named module cannot import a module partition directly).
 * 
 * A module partition can be imported by module units of the same named module.
 * 
 * All definitions and declarations in a module partition are visible by the importing module unit,
 * whether exported or not.
 * 
 * Module partitions can be module interface units (when their module declarations have export).
 * They must be export-imported by the primary module interface unit, and their exported statements
 * will be visible when the module is imported.
 */

export module math;

export import :math1;
export import :math2;

export float get_pi() {
	return my_pi; // my_pi is not exported but visible here.
}
