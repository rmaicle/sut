module sut.prologue;

import sut.color;
import sut.counter;
import sut.output;
import sut.execlist:
    isExecListEmpty,
    isInModuleExecList,
    isInUnitTestExecList,
    isUnitTestBlockExecuted;

debug import std.stdio;



/**
 * Generate a compile-time string used in a mixed-in to:
 *   - get the unit test block name whether it is a user-supplied name using
 *     a user-defined string attribute (UDA) or the default unit test name.
 *   - call the actual function that displays the unit test block info and
 *     execution status.
 *
 * Params:
 *   skipFlag - pass `false` to skip execution of the rest of the unit test
 *              block.
 *
 * Returns: string
 *
 * Example:
 *
 * ~~~~~~~~~~
 * static import sut;
 * ...
 * unittest {
 *     mixin (sut.unitTestBlockPrologue());
 * }
 * ~~~~~~~~~~
 */
string
unitTestBlockPrologue (size_t LN = __LINE__)(const bool skipFlag = true)
{
    import std.conv: to;
    import std.format: format;

    // Because this function is intended to be called from the first line
    // of the unit test block, we hard code the line number.
    //
    // NOTE:
    //
    // The mixin is assumed to be defined as:
    //   enum prologue=`
    //       static if (__traits(compiles, { import sut; })) {
    //           mixin (???.sut.unitTestBlockPrologue());
    //       }
    //   `;
    //
    // and used as:
    //
    //   @("unittest label or identifier string")
    //   unittest {
    //     mixin (???.sut.prologue);
    //   }
    //
    // which translates to:
    //
    //   @("unittest label or identifier string")
    //   unittest {                                          <-- LN - 3
    //     mixin (`
    //       static if (__traits(compiles, { import sut; })) {
    //           mixin (???.sut.unitTestBlockPrologue());    <-- LN
    //       }
    //     `);
    //   }
    //
    enum UTLineNumber = LN - 3;
    // Create possible non-conflicting identifiers for module name and unit
    // test name which are used only within the calling unit test block.
    enum ModuleName = format!("module_name_L%d__")(UTLineNumber);
    enum UnitTestName = format!("unit_test_name_L%d__")(UTLineNumber);

    return `static import sut;
import std.traits: moduleName;
struct unit_test_dummy_anchor { }` ~
format!("\nenum %s = sut.getUTNameFunc!unit_test_dummy_anchor;")(UnitTestName) ~
format!("\nenum %s = moduleName!unit_test_dummy_anchor;")(ModuleName) ~
format!("\nif (!sut.executeUnitTestBlock!(%s, %s, %d)(%s)) { return; }")(
    ModuleName,
    UnitTestName,
    UTLineNumber,
    skipFlag.to!string);
}



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
    mixin (unitTestBlockPrologue());
    @("string variable")
    string stringVar;
    static assert (isStringUDA!(__traits(getAttributes, stringVar)));
}
@("isStringUDA: not a string")
unittest {
    mixin (unitTestBlockPrologue());
    @(123)
    int intVar;
    static assert (isStringUDA!(__traits(getAttributes, intVar)) == false);
}



/**
 * Get the first string user-defined attribute (UDA) of the unit test block
 * if one is present. Otherwise, an empty string.
 */
template
firstStringUDA (alias testFunction)
{
    import std.traits: hasUDA, getUDAs;
    import std.meta: Filter;
    enum attributes = Filter!(isStringUDA, __traits(getAttributes, testFunction));
    static if (attributes.length > 0) {
        enum firstStringUDA = attributes[0];
    } else {
        enum firstStringUDA = "";
    }
}
@("firstStringUDA: string")
unittest {
    mixin (unitTestBlockPrologue());
    @("123")
    int intVar;
    static assert (firstStringUDA!intVar == "123");
}
@("firstStringUDA: integer")
unittest {
    mixin (unitTestBlockPrologue());
    @(123)
    int intVar;
    static assert (firstStringUDA!intVar == string.init);
}
@("firstStringUDA: empty")
unittest {
    mixin (unitTestBlockPrologue());
    int intVar;
    static assert (firstStringUDA!intVar == string.init);
}



/**
 * Get the unit test function name as a string.
 *
 * If the unit test block has a user-defined string attribute then it is used
 * as the name of the unit test block. Otherwise, use the compiler generated
 * name.
 *
 * Returns: string
 */
string
getUTNameFunc (alias T)() pure nothrow
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
executeUnitTestBlock (
    const string ModuleName = __MODULE__,
    const string FunctionName = __FUNCTION__,
    const size_t LineNo = __LINE__
)(
    const bool skipFlag = false
) {
    import std.string: toStringz;
    import core.stdc.stdio: printf, fflush, stdout;

    bool
    proceedToExecute (const bool flag) {
        // Assume it passed first
        // If an assertion occurs, subtract 1 in the exception handler code
        moduleCounter.pass++;

        printf("%s %s %zd:%s%s%s\n",
            Label.NoGroupLabel.toStringz,
            ModuleName.toStringz,
            LineNo,
            Color.Green.toStringz,
            FunctionName.toStringz,
            Color.Reset.toStringz);
        fflush(stdout);
        return flag;
    }

    moduleCounter.found++;
    version (sut) {
        // Filter if a selection is present. Otherwise, execute all.
        if (isExecListEmpty) {
            isUnitTestBlockExecuted = true;
            return proceedToExecute(true);
        }
        if (isInModuleExecList(ModuleName)) {
            if (!isUnitTestBlockExecuted) {
                isUnitTestBlockExecuted = true;
                printModuleStart(ModuleName);
            }
            return proceedToExecute(skipFlag);
        } else {
            if (isInUnitTestExecList(FunctionName)) {
                if (!isUnitTestBlockExecuted) {
                    isUnitTestBlockExecuted = true;
                    printModuleStart(ModuleName);
                }
                return proceedToExecute(skipFlag);
            }
        }
        moduleCounter.skip++;
        return true;
    } else {
        //return proceedToExecute(true);
        return true;
    }
}
