// TODO: Rename to Exclude.
//       User deliberately excluded a module


module sut.skiplist;

import sut.util:
    dedup,
    remove;

debug import std.stdio;



/**
 * List of packages.
 *
 * Module names found in this list are not reported as having no unit tests.
 */
__gshared
static
string[] moduleList;



/**
 * Client-facing mixin code for adding the module into the skip list.
 */
string
skipModule (size_t LN = __LINE__)()
{
    import std.format: format;
    enum ModuleName = format!("module_name_L%d__")(LN);
    return `static this () {
    static import sut;
    import std.traits: moduleName;
    struct dummyXYZ { }` ~
    format!("\nenum %s = moduleName!dummyXYZ;")(ModuleName) ~
    format!("sut.add(moduleName!%s);")(ModuleName) ~
    "}";
}



/**
 * Append an item in the list.
 */
void
add (const string arg)
{
    moduleList ~= arg;
}



bool
isFound (const string arg)
{
    import std.algorithm: canFind;
    return moduleList.canFind(arg);
}



string[]
filter (const string[] arg)
{
    return moduleList.dedup.remove(arg);
}
