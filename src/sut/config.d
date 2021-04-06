module sut.config;

import sut.prologue;
import sut.util:
    toArray,
    unprefix;

debug import std.stdio;



/**
 * Contains the path where the file `unittest.conf` can be found.
 */
version (none) {
    enum UNITTEST_CONFIG_FILE_PATH_FILE = "unittest.conf.path";
}
/**
 * Unit test configuration file.
 *
 * This is where unit tests that will be executed are specified.
 * If this file is empty, then all unit tests will be executed.
 *
 * Unit test blocks are specified using the `utb` keyword.
 * Unit test modules are specified using the `utm` keyword.
 */
enum UNITTEST_CONFIG_FILE = "unittest.conf";
enum BLOCK_PREFIX = "utb:";
enum MODULE_PREFIX = "utm:";



/**
 * Determine if the file `UNITTEST_CONFIG_FILE` exists in the path contained
 * in `UNITTEST_CONFIG_FILE_PATH_FILE`
 *
 * Returns: `true` if the file exists.
 */
version (none) {
    bool
    configFileExists ()
    {
        import std.file: exists;
        import std.string: join;

        enum UnitTestConfigFilePath = import(UNITTEST_CONFIG_FILE_PATH_FILE);
        return [UnitTestConfigFilePath, "/", UNITTEST_CONFIG_FILE].join.exists();
    }
}



/**
 * Read the contents of `UNITTEST_CONFIG_FILE`.
 *
 * Returns: `string`
 */
string
readConfigFile ()
{
    return import(UNITTEST_CONFIG_FILE);
}







/**
 * Filter the string array argument containing the prefix string 'utb:'.
 *
 * Returns: `string[]` without the prefix string 'utb:'.
 */
string[]
getUnitTestBlocks (const string[] arg)
{
    if (arg.length == 0) {
        return (string[]).init;
    }
    return unprefix(arg, BLOCK_PREFIX);
}
@("getUnitTestBlocks: empty array")
unittest {
    //mixin (unitTestBlockPrologue());
    assert ((string[]).init.getUnitTestBlocks == []);
}
@("getUnitTestBlocks")
unittest {
    //mixin (unitTestBlockPrologue());
    string[] arr = [
        "utb:one",
        "utb:two",
        "utm:three",
        "",
        "utm:four"
    ];
    assert (arr.getUnitTestBlocks == ["one", "two"]);
}



/**
 * Filter the string array argument containing the prefix string 'utm:'.
 *
 * Returns: `string[]` without the prefix string 'utm:'.
 */
string[]
getModules (const string[] arg)
{
    if (arg.length == 0) {
        return (string[]).init;
    }
    return unprefix(arg, MODULE_PREFIX);
}
@("getModules: empty array")
unittest {
    //mixin (unitTestBlockPrologue());
    assert ((string[]).init.getModules == []);
}
@("getModules")
unittest {
    //mixin (unitTestBlockPrologue());
    string[] arr = [
        "utb:one",
        "utb:two",
        "utm:three",
        "",
        "utm:four"
    ];
    assert (arr.getModules == ["four", "three"]);
}



