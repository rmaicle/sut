module sut.execlist;

import sut.prologue;
import sut.config:
    getModules,
    getUnitTestBlocks;
import sut.util:
    beginsWith,
    isFound,
    isIn,
    toArray;

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
 * Only used to determine whether a unit test block has been executed.
 */
__gshared
static
bool isUnitTestBlockExecuted;



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
 * Populate the unit test block and module execution lists.
 *
 */
void
getExecutionList (const string arg = string.init)
{
    const arr = arg.toArray();
    unitTestExecList = arr.getUnitTestBlocks();
    moduleExecList = arr.getModules();
}
@("getExecutionList: setup and teardown helper")
version (unittest) {

    struct ExecList
    {
        string[] modules;
        string[] unittests;

        static
        ExecList
        save ()
        {
            ExecList e;
            e.modules = moduleExecList;
            e.unittests = unitTestExecList;
            return e;
        }

        static
        void
        restore (const ExecList arg)
        {
            moduleExecList = arg.modules.dup;
            unitTestExecList = arg.unittests.dup;
        }
    }
}
@("getExecutionList: empty string")
unittest {
    //mixin (unitTestBlockPrologue());
    auto e = ExecList.save();
    getExecutionList();
    assert (moduleExecList == (string[]).init);
    assert (unitTestExecList == (string[]).init);
    ExecList.restore(e);
}
@("getExecutionList: spaces and new lines only")
unittest {
    //mixin (unitTestBlockPrologue());
    auto e = ExecList.save();
    enum INPUT=" \n \n \n";
    getExecutionList(INPUT);
    assert (moduleExecList == (string[]).init);
    assert (unitTestExecList == (string[]).init);
    ExecList.restore(e);
}
@("getExecutionList: unit test blocks")
unittest {
    //mixin (unitTestBlockPrologue());
    auto e = ExecList.save();
    enum INPUT="utb:one\nutb:two\n\nutb:three";
    getExecutionList(INPUT);
    assert (moduleExecList == (string[]).init);
    assert (unitTestExecList == ["one", "three", "two"]);
    ExecList.restore(e);
}
@("getExecutionList: unit test modules")
unittest {
    //mixin (unitTestBlockPrologue());
    auto e = ExecList.save();
    enum INPUT="utm:one\nutm:two\n\nutm:three";
    getExecutionList(INPUT);
    assert (moduleExecList == ["one", "three", "two"]);
    assert (unitTestExecList == (string[]).init);
    ExecList.restore(e);
}



/**
 * Determine whether the execution lists are empty.
 *
 * Returns: `true` when unit test and module execution lists are empty.
 */
bool
isExecutionListEmpty ()
{
    return unitTestExecList.length == 0 && moduleExecList.length == 0;
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
    //mixin (unitTestBlockPrologue());
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
    version (sut_include_unittests) {
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
@("isInternalModule")
unittest {
    //mixin (unitTestBlockPrologue());
    version (sut_include_unittests) {
        version (sut) {
            assert (!isInternalModule(__MODULE__));
        } else {
            assert (isInternalModule(__MODULE__));
        }
    } else {
        assert (isInternalModule(__MODULE__));
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
