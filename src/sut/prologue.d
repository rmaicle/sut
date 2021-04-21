module sut.prologue;

import sut.counter: unitTestCounter;
import sut.output: printUnitTestInfo;
import sut.execution: executionList;

static import sut.wrapper;

debug import std.stdio;



/**
 * Generate the code to be passed to a mixin expression in the calling unit
 * test block.
 *
 * The generated code determines whether to continue execution of the rest of
 * the unit test block or to return early.
 */
string
unitTestBlockPrologue (const size_t LineNumber = __LINE__)()
{
    // Because this string is intended and assumed to be passed to a mixin
    // expression at the first line of the unit test block, the line number
    // of the unit test entry block point is calculated to be less than.
    //
    // This is the solution for now until a more reliable way is found on how
    // to get the actual line number of the unit test block entry point.
    //
    //   @("unittest label or identifier string")
    //   unittest {                                 <-- prologue - 1
    //     mixin (???.unitTestBlockPrologue());     <-- prologue
    //   }

    import std.format: format;
    return format!`
    static import sut;
    import std.traits: moduleName;

    struct dummyXYZ { }

    sut.unitTestCounter.unitTestBlock.enter();
    scope (exit) sut.unitTestCounter.unitTestBlock.leave();

    sut.unitTestCounter.addModulesWithPrologue(moduleName!dummyXYZ);
    bool executeBlockFlag = sut.executeBlock!(
        moduleName!dummyXYZ,
        sut.getUnitTestName!dummyXYZ,
        %d);
    if (executeBlockFlag == false) {
        return;
    }`(LineNumber - 1);
}



/**
 * Get unit test name of template argument.
 *
 * Unit test name is the first user-defined string attribute or the
 * compiler-generated name of the parent symbol of the template argument.
 *
 * Returns: string
 */
string
getUnitTestName (alias T)() pure nothrow
{
    enum udaName = firstStringUDA!(__traits (parent, T));
    static if (udaName == string.init) {
        return __traits (identifier, __traits (parent, T));
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
)() {

    bool
    proceedToExecute ()
    {
        // Assume it passed first
        // If an assertion occurs, subtract 1 in the exception handler code
        unitTestCounter.current.addPassing();
        printUnitTestInfo(ModuleName, UnitTestName, Line, unitTestCounter);
        return true;
    }

    version (sut) {
        unitTestCounter.current.addTotal();
        // Filter if a selection is present. Otherwise, execute all.
        if (executionList.isEmpty()) {
            return proceedToExecute();
        }
        if (executionList.isModuleFound(ModuleName)) {
            return proceedToExecute();
        }
        if (executionList.isUnitTestFound(UnitTestName)) {
            return proceedToExecute();
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
    static if (__traits (compiles, isSomeString!(typeof (T)))) {
        enum isStringUDA = isSomeString!(typeof (T));
    } else {
        enum isStringUDA = false;
    }
}
@("isStringUDA: string")
unittest {
    mixin (sut.wrapper.prologue);
    @("string variable")
    string stringVar;
    static assert (isStringUDA!(__traits (getAttributes, stringVar)));
}
@("isStringUDA: not a string")
unittest {
    mixin (sut.wrapper.prologue);
    @(123)
    int intVar;
    static assert (isStringUDA!(__traits (getAttributes, intVar)) == false);
}



/**
 * Get the first string user-defined attribute (UDA) of the alias argument
 * if one is present. Otherwise, an empty string.
 */
template
firstStringUDA (alias T)
{
    import std.meta: Filter;
    enum attributes = Filter!(isStringUDA, __traits (getAttributes, T));
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
