module sut.prologue;

import sut.counter: unitTestCounter;
import sut.output: printUnitTestInfo;
import sut.execution: executionList;

static import sut.wrapper;

debug import std.stdio;



/**
 * Client-facing mixin code to determine whether to continue execution
 * of the unit test block or to return early.
 */
string
unitTestBlockPrologue (size_t LN = __LINE__)()
{
    import std.format: format;

    // Because this function is intended to be called from the first line
    // of unit test blocks, we hard code the line number.
    //
    // NOTE:
    //
    // The result of this function is passed to a mixin statement.
    //
    //   @("unittest label or identifier string")
    //   unittest {                                 <-- LN - 1
    //     mixin (???.unitTestBlockPrologue());     <-- LN
    //   }
    //
    enum LineNumber = LN - 1;
    // Create possible non-conflicting identifiers for module name and unit
    // test name which are used only within the calling unit test block.
    enum ModuleName = format!("module_name_L%d__")(LineNumber);
    enum UnitTestName = format!("unit_test_name_L%d__")(LineNumber);

    return `static import sut;
import std.traits: moduleName;
class dummyXYZ { }
sut.unitTestCounter.unitTestBlock.enter();
scope (exit) sut.unitTestCounter.unitTestBlock.leave();` ~
format!("\nenum %s = sut.getUnitTestName!dummyXYZ;")(UnitTestName) ~
format!("\nenum %s = moduleName!dummyXYZ;")(ModuleName) ~
format!("\nsut.unitTestCounter.addModulesWithPrologue(%s);")(ModuleName) ~
format!("\nif (sut.executeBlock!(%s, %s, %d)() == false) { return; }")(
    ModuleName,
    UnitTestName,
    LineNumber);
}



/**
 * Get unit test name.
 *
 * Unit test name is the first user-defined string attribute or the
 * compiler-generated name.
 *
 * Returns: string
 */
string
getUnitTestName (alias T)() pure nothrow
{
    enum udaName = firstStringUDA!(__traits(parent, T));
    static if (udaName == string.init) {
        return __traits(identifier, __traits(parent, T));
    } else {
        return udaName;
    }
}



/**
 * Execute unit test block.
 *
 * To skip execution of a unit test block, pass `false` or an expression that
 * evaluates to `false`.
 *
 * Returns: `true` by default. When `sut` version identifier is defined, the
 *          return value is the boolean argument.
 */
bool
executeBlock (
    const string ModuleName,
    const string UnitTestName,
    const size_t Line
)()
{
    import std.string: toStringz;
    import core.stdc.stdio: printf, fflush, stdout;

    bool
    proceedToExecute (const bool flag) {
        // Assume it passed first
        // If an assertion occurs, subtract 1 in the exception handler code
        unitTestCounter.current.addPassing();
        printUnitTestInfo(ModuleName, UnitTestName, Line, unitTestCounter);
        return flag;
    }

    version (sut) {
        unitTestCounter.current.addTotal();
        // Filter if a selection is present. Otherwise, execute all.
        if (executionList.isEmpty()) {
            return proceedToExecute(true);
        }
        if (executionList.isModuleFound(ModuleName)) {
            return proceedToExecute(true);
        }
        if (executionList.isUnitTestFound(UnitTestName)) {
            return proceedToExecute(true);
        }
        return false;
    } else {
        return true;
    }
}



private:



/**
 * Determine whether the template argument is some string.
 */
template
isStringUDA (alias T)
{
    import std.traits: isSomeString;
    static if (__traits(compiles, isSomeString!(typeof(T)))) {
        enum isStringUDA = isSomeString!(typeof(T));
    } else {
        enum isStringUDA = false;
    }
}
@("isStringUDA: string")
unittest {
    mixin (sut.wrapper.prologue);
    @("string variable")
    string stringVar;
    static assert (isStringUDA!(__traits(getAttributes, stringVar)));
}
@("isStringUDA: not a string")
unittest {
    mixin (sut.wrapper.prologue);
    @(123)
    int intVar;
    static assert (isStringUDA!(__traits(getAttributes, intVar)) == false);
}



/**
 * Get the first string user-defined attribute (UDA) of the alias argument
 * if one is present. Otherwise, an empty string.
 */
template
firstStringUDA (alias T)
{
    import std.traits: hasUDA, getUDAs;
    import std.meta: Filter;
    enum attributes = Filter!(isStringUDA, __traits(getAttributes, T));
    static if (attributes.length > 0) {
        enum firstStringUDA = attributes[0];
    } else {
        enum firstStringUDA = "";
    }
}
@("firstStringUDA: string")
unittest {
    mixin (sut.wrapper.prologue);
    @("123")
    int intVar;
    static assert (firstStringUDA!intVar == "123");
}
@("firstStringUDA: integer")
unittest {
    mixin (sut.wrapper.prologue);
    @(123)
    int intVar;
    static assert (firstStringUDA!intVar == string.init);
}
@("firstStringUDA: empty")
unittest {
    mixin (sut.wrapper.prologue);
    int intVar;
    static assert (firstStringUDA!intVar == string.init);
}
