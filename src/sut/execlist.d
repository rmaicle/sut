module sut.execlist;

import sut.prologue;
import sut.config;

debug import std.stdio;



/**
 * Module execution list.
 *
 * A collection of module names that will be allowed to execute the module's
 * unit tests.
 */
__gshared
static
string[] moduleExecList;



/**
 * Unittest block execution list.
 *
 * A collection of unittest blocks that will be allowed to execute.
 */
__gshared
static
string[] unitTestExecList;



/**
 * Only used to cache the result whether both `moduleExecList` and
 * `unitTestExecList` are empty.
 */
__gshared
static
bool isExecListEmpty;



/**
 * Only used to determine whether a unit test block has been executed.
 */
__gshared
static
bool isUnitTestBlockExecuted;



/**
 * Determine whether the `needle` is found in the `haystack` using the
 * specified predicate, `pred`, on how to find the `needle`.
 */
bool
isIn (alias pred)(
    const string[] haystack,
    const string needle
) {
    import std.algorithm: canFind;
    import std.uni: toLower;
    if (haystack.length == 0) {
        return false;
    }
    if (needle.length == 0) {
        return false;
    }
    return canFind!(pred)(haystack, needle);
}



bool
beginsWith (
    const string[] haystack,
    const string needle
) {
    import std.algorithm: startsWith;
    import std.uni: toLower;
    return isIn!(
        (string a, string b) => b.startsWith(a.toLower))
        (haystack, needle.toLower);
}
@("beginsWith: empty")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr;
    assert (!arr.beginsWith(__MODULE__));
}
@("beginsWith: exact")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.beginsWith("aaa"));
    assert (!arr.beginsWith(""));
    assert (!arr.beginsWith("any"));
}
@("beginsWith: begins with")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.beginsWith("aaa111"));
    assert (arr.beginsWith("bbb222"));
    assert (arr.beginsWith("ccc333"));
    assert (!arr.beginsWith("111aaa"));
}



bool
isFound (
    const string[] haystack,
    const string needle
) {
    import std.algorithm: canFind;
    import std.uni: toLower;
    return isIn!(
        (string a, string b) => b.canFind(a.toLower))
        (haystack, needle.toLower);
}
@("isFound: empty")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr;
    assert (!arr.isFound("aaa"));
}
@("isFound: exact")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.isFound("aaa"));
    assert (!arr.isFound(""));
    assert (!arr.isFound("ddd"));
}
@("isFound: substring")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.isFound("aaa111"));
    assert (!arr.isFound(""));
    assert (!arr.isFound("ddd"));
}



/**
 * Determine whether the string argument begins with any entry in the module
 * execution list.
 *
 * Returns: `true` if a match is found.
 */
bool
isInModuleExecList (const string arg)
{
    return beginsWith(moduleExecList, arg);
}



/**
 * Determine whether the string argument matches any entry in the unit test
 * execution list.
 *
 * Returns: `true` if a match is found.
 */
bool
isInUnitTestExecList (const string arg)
{
    return isFound(unitTestExecList, arg);
}



/**
 * Get the module and unittest block execution list.
 *
 * Returns: `string[]`
 */
string[]
getExecutionList (const string INPUT)()
{
    enum arr = INPUT.toArray();
    unitTestExecList = arr.getUnitTestBlocks();
    moduleExecList = arr.getModules();
    isExecListEmpty = unitTestExecList.length == 0 && moduleExecList.length == 0;
    return arr;
}
@("getExecutionList: empty string")
unittest {
    mixin (unitTestBlockPrologue());

    auto unitTestExecListCopy = unitTestExecList;
    auto moduleExecListCopy = moduleExecList;
    auto isExecListEmptyCopy = isExecListEmpty;

    enum input="";
    assert (getExecutionList!input == (string[]).init);

    unitTestExecList = unitTestExecListCopy;
    moduleExecList = moduleExecListCopy;
    isExecListEmpty = isExecListEmptyCopy;
}
@("getExecutionList: spaces and new lines only")
unittest {
    mixin (unitTestBlockPrologue());

    auto unitTestExecListCopy = unitTestExecList;
    auto moduleExecListCopy = moduleExecList;
    auto isExecListEmptyCopy = isExecListEmpty;

    enum input=" \n \n \n";
    assert (getExecutionList!input == (string[]).init);

    unitTestExecList = unitTestExecListCopy;
    moduleExecList = moduleExecListCopy;
    isExecListEmpty = isExecListEmptyCopy;
}
@("getExecutionList")
unittest {
    mixin (unitTestBlockPrologue());

    auto unitTestExecListCopy = unitTestExecList;
    auto moduleExecListCopy = moduleExecList;
    auto isExecListEmptyCopy = isExecListEmpty;

    enum input="aaa\nbbb\nccc";
    assert (getExecutionList!input == ["aaa", "bbb", "ccc"]);

    unitTestExecList = unitTestExecListCopy;
    moduleExecList = moduleExecListCopy;
    isExecListEmpty = isExecListEmptyCopy;
}



/**
 * Determine whether the string argument corresponds to any D language module
 * name.
 *
 * Returns: `true` if the argument is a D language module.
 */
bool
isLanguageModule (const string mod)
{
    import std.algorithm: startsWith;
    // Module invariant has been added since it keeps on appearing when
    // reporting the total number of modules processed even though
    // there is no invariant module present. What is it really?
    return mod.startsWith("__main")
        || mod.startsWith("core")
        || mod.startsWith("etc")
        || mod.startsWith("invariant")
        || mod.startsWith("gc")
        || mod.startsWith("object")
        || mod.startsWith("rt")
        || mod.startsWith("std")
        || mod.startsWith("ldc");
}
@("isLanguageModule")
unittest {
    mixin (unitTestBlockPrologue());
    assert (isLanguageModule("__main"));
    assert (isLanguageModule("core.submodule"));
    assert (isLanguageModule("etc.submodule"));
    assert (isLanguageModule("gc.submodule"));
    assert (isLanguageModule("gc.submodule"));
    assert (isLanguageModule("object.submodule"));
    assert (isLanguageModule("rt.submodule"));
    assert (isLanguageModule("std.submodule"));
}



/**
 * Determines whether the string argument is equivalent to the package module's
 * name `sut` This check is only performed when unit testing is enabled and the
 * version identifier `sut` is not defined.
 *
 * Returns: `true` if the string argument is equivalent to this module's name.
 */
bool
isInternalModule (const string mod)
{
    import std.algorithm: canFind, startsWith;
    version (exclude_sut) {
        if (mod.canFind(".")) {
            const bool match = mod.startsWith("sut.") || mod.canFind(".sut");
            return match;
        } else {
            const bool match = mod.startsWith("sut") || mod.canFind("sut");
            return match;
        }
    } else {
        version (sut) {
            return false;
        } else {
            if (mod.canFind(".")) {
                const bool match = mod.startsWith("sut.") || mod.canFind(".sut");
                return match;
            } else {
                const bool match = mod.startsWith("sut") || mod.canFind("sut");
                return match;
            }
        }
    }
}
@("isInternalModule")
unittest {
    mixin (unitTestBlockPrologue());
    version (exclude_sut) {
        assert (isInternalModule(__MODULE__));
    } else {
        version (sut) {
            assert (!isInternalModule(__MODULE__));
        } else {
            assert (isInternalModule(__MODULE__));
        }
    }
    assert (!isInternalModule("__main"));
    assert (!isInternalModule("core.submodule"));
    assert (!isInternalModule("etc.submodule"));
    assert (!isInternalModule("gc.submodule"));
    assert (!isInternalModule("gc.submodule"));
    assert (!isInternalModule("object.submodule"));
    assert (!isInternalModule("rt.submodule"));
    assert (!isInternalModule("std.submodule"));
}
