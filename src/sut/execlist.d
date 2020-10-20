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



version (sut_override) {
    version (sut) version = selective_unit_test;
} else {
    version (sut) version = selective_unit_test;
}



bool
isIn (alias pred)(
    const string[] haystack,
    const string needle
) {
    version (selective_unit_test) {
        import std.algorithm: canFind;
        import std.uni: toLower;
        if (haystack.length == 0) {
            return false;
        }
        if (needle.length == 0) {
            return false;
        }
        return canFind!(pred)(haystack, needle);
    } else {
        // This check is unlikely to happen except when the routine that
        // fetches unit test block names get it wrong.
        if (needle.length == 0) {
            return false;
        }
        return true;
    }
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
    version (sut) {
        assert (!arr.beginsWith(__FUNCTION__));
    } else {
        assert (arr.beginsWith(__FUNCTION__));
    }
}
@("beginsWith: exact")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.beginsWith("aaa"));
    version (sut) {
        assert (!arr.beginsWith(""));
        assert (!arr.beginsWith("any"));
    } else {
        version (sut_override) {
            assert (!arr.beginsWith(""));
            assert (arr.beginsWith("any"));
        } else {
            assert (arr.beginsWith(""));
            assert (arr.beginsWith("any"));
        }
    }
}
@("beginsWith: begins with")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.beginsWith("aaa111"));
    assert (arr.beginsWith("bbb222"));
    assert (arr.beginsWith("ccc333"));
    version (sut) {
        assert (!arr.beginsWith("111aaa"));
    } else {
        version (sut_override) {
            assert (arr.beginsWith("111aaa"));
        } else {
            assert (arr.beginsWith("111aaa"));
        }
    }
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
    const string[] arr = ["aaa", "bbb", "ccc"];
    version (sut) {
        assert (arr.isFound("aaa"));
    } else {
        assert (arr.isFound("aaa"));
    }
}
@("isFound: exact")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.isFound("aaa"));
    version (sut) {
        assert (!arr.isFound(""));
        assert (!arr.isFound("ddd"));
    } else {
        assert (!arr.isFound(""));
        assert (arr.isFound("ddd"));
    }
}
@("isFound: substring")
unittest {
    mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    version (sut) {
        assert (arr.isFound("aaa111"));
        assert (!arr.isFound(""));
        assert (!arr.isFound("ddd"));
    } else {
        version (sut_override) {
            assert (arr.isFound("aaa111"));
            assert (!arr.isFound(""));
            assert (arr.isFound("ddd"));
        } else {
            assert (arr.isFound("aaa111"));
            assert (arr.isFound(""));
            assert (arr.isFound("ddd"));
        }
    }
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
    return arr;
}
@("getExecutionList: empty string")
unittest {
    mixin (unitTestBlockPrologue());
    enum input="";
    assert (getExecutionList!input == (string[]).init);
}
@("getExecutionList: spaces and new lines only")
unittest {
    mixin (unitTestBlockPrologue());
    enum input=" \n \n \n";
    assert (getExecutionList!input == (string[]).init);
}
@("getExecutionList")
unittest {
    mixin (unitTestBlockPrologue());
    enum input="aaa\nbbb\nccc";
    assert (getExecutionList!input == ["aaa", "bbb", "ccc"]);
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
        || mod.startsWith("std");
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
 * Determines whether the string argument is equivalent to this module's name.
 *
 * Returns: `true` if the string argument is equivalent to this module's name.
 */
bool
isInternalModule (const string mod)
{
    version (sut_override) {
        return false;
    } else {
        import std.algorithm: canFind, startsWith;
        const bool match = mod.startsWith("sut.") || mod.canFind(".sut");
        return match;
    }
}
@("isInternalModule")
unittest {
    mixin (unitTestBlockPrologue());
    version (sut_override) {
        assert (!isInternalModule(__MODULE__));
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
