module sut.config;

import sut.prologue;
import std.file: exists;

debug import std.stdio;


enum UNITTEST_CONFIG_FILE = "unittest.conf";
enum BLOCK_PREFIX = "utb:";
enum MODULE_PREFIX = "utm:";



/**
 * Convert string argument into array of string, stripped of whitespaces, and
 * duplicates removed.
 *
 * Returns: `string[]`
 */
string[]
toArray (const string arg)
{
    import std.algorithm: map, remove, sort, uniq;
    import std.array: array;
    import std.string: strip, splitLines;
    import std.uni: toLower;

    if (arg.length == 0) {
        return (string[]).init;
    }
    return arg.splitLines()
        .map!(a => a.strip()).array()
        .sort!("toLower(a) < toLower(b)").release()
        .uniq().array()
        .remove!("a.length == 0").array();
}
@("toArray: empty array")
unittest {
    mixin (unitTestBlockPrologue());
    assert ("".toArray() == []);
}
@("toArray: with empty array element")
unittest {
    mixin (unitTestBlockPrologue());
    const arr = " one\n \n two ";
    assert (arr.toArray() == ["one", "two"]);
}
@("toArray")
unittest {
    mixin (unitTestBlockPrologue());
    const arr = " one\ntwo \n three \nfour\none\n   two ";
    assert (arr.toArray() == ["four", "one", "three", "two"]);
}



/**
 * Filter the array of string argument containing the prefix string 'utb:'.
 *
 * Returns: `string[]` without the prefix string 'utb:'.
 */
string[]
getUnitTestBlocks (const string[] arg)
{
    if (arg.length == 0) {
        return (string[]).init;
    }
    return removePrefix(arg, BLOCK_PREFIX);
}
@("getUnitTestBlocks: empty array")
unittest {
    mixin (unitTestBlockPrologue());
    assert ((string[]).init.getUnitTestBlocks == []);
}
@("getUnitTestBlocks")
unittest {
    mixin (unitTestBlockPrologue());
    string[] arr = [
        "utb:one",
        "",
        "utb:two",
        "three",
        "four"
    ];
    assert (arr.getUnitTestBlocks == ["one", "two"]);
}



/**
 * Filter the array of string argument containing the prefix string 'mod:'.
 *
 * Returns: `string[]` without the prefix string 'mod:'.
 */
string[]
getModules (const string[] arg)
{
    if (arg.length == 0) {
        return (string[]).init;
    }
    return removePrefix(arg, MODULE_PREFIX);
}
@("getModules: empty array")
unittest {
    mixin (unitTestBlockPrologue());
    assert ((string[]).init.getModules == []);
}
@("getModules")
unittest {
    mixin (unitTestBlockPrologue());
    string[] arr = [
        "utb:one",
        "utb:two",
        "utm:three",
        "",
        "utm:four"
    ];
    assert (arr.getModules == ["three", "four"]);
}



/**
 * Filter the array of string argument containing the specified prefix argument
 * irrespective of case variance.
 *
 * Returns: `string[]` without the specified prefix.
 */
string[]
removePrefix (
    const string[] arg,
    const string prefix
) {
    import std.algorithm: filter, map;
    import std.array: array;
    import std.string: startsWith;
    import std.uni: toLower;

    if (arg.length == 0) {
        return (string[]).init;
    }
    return arg.filter!(a => a.toLower.startsWith(toLower(prefix)))
        .map!(a => a[prefix.length..$]).array();
}
@("removePrefix: empty array")
unittest {
    mixin (unitTestBlockPrologue());
    assert ((string[]).init.removePrefix("") == []);
}
@("removePrefix: empty prefix")
unittest {
    mixin (unitTestBlockPrologue());
    string[] arr = [
        "prefix:one",
        "PREFIX:two",
        "three",
        "four"
    ];
    assert (removePrefix(arr, "") == ["prefix:one", "PREFIX:two", "three", "four"]);
}
@("removePrefix")
unittest {
    mixin (unitTestBlockPrologue());
    string[] arr = [
        "prefix:one",
        "PREFIX:two",
        "three",
        "four"
    ];
    assert (removePrefix(arr, "prefix:") == ["one", "two"]);
}
