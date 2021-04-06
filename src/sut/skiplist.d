module sut.skiplist;

import sut.util:
    dedup,
    remove;

debug import std.stdio;



/**
 * List of packages.
 *
 * Packages are meant to 'package' modules and therefore are usually not meant
 * to contain unit tests.
 * Module names found in this list are not reported to having no unit tests.
 */
__gshared
static
string[] packageList;



string
skipPackage (size_t LN = __LINE__)()
{
    import std.format: format;
    enum ModuleName = format!("module_name_L%d__")(LN);
    return `
static this () {
static import sut;
import std.traits: moduleName;` ~
format!("\nenum %s = moduleName!moduleName;")(ModuleName) ~
format!("\nsut.addToPackageList(%s);")(ModuleName) ~
`}`;
}



void
addToPackageList (const string arg)
{
    packageList ~= arg;
}


string[]
filter (const string[] arg)
{
    return packageList.dedup.remove(arg);
}
