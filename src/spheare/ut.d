module spheare.ut;

/++
 + A simple unit test helper that allows selective module unit test
 + and unit test block execution.
 +
 + To allow this capability, execution of all unit tests must be
 + aborted when the compiler option `-unittest` is passed to the
 + compiler. Then there must be a check in place that tests whether
 + a module unit test and a unit test block is included in the
 + execution list.
 +
 + Selective Module Unit Test Execution:
 +
 + Importing this module will initialize the necessary configuration.
 + This module sets a custom assert handler and a custom unit test
 + handler.
 +
 + ~~~~~~~~~~
 + import core.runtime;
 + import core.exception: assertHandler;
 +
 + shared static this () {
 +   assertHandler(&csAssertHandler);
 +   Runtime.extendedModuleUnitTester = &customModuleUnitTester;
 + }
 + ~~~~~~~~~~
 +
 + The custom unit test handler will not execute all unit tests (when
 + the option `unittest` is passed to the compiler) unless the module
 + has been included in an execution list.
 +
 + To allow execution of a module unit test, the `includeUnitTest`
 + function must be called in the module's static initializer.
 +
 + ~~~~~~~~~~
 + version (unittest) import spheare.ut;
 +
 + shared static this() {
 +     version (unittest) includeUnitTest();
 + }
 + ~~~~~~~~~~
 +
 + Reverting to the Default Behavior:
 +
 + To exclude the execution of the module unit tests, the call to the
 + `includeUnitTest` function may be commented out or deleted. Passing
 + a value that evaluates to `false` will also do the equivalent.
 +
 + But if commenting out and/or deleting lines of code is undesired,
 + the default behavior may be tapped by passing a version identifier
 + `version=execute_all_unit_tests` to the compiler along with the
 + `-unittest` compiler option. This also overrides the selective unit
 + test block execution described below.
 +
 + Selective Unit Test Block Execution:
 +
 + Although unnecessary at first, but this capability allows fine-
 + grained testing and debugging of functions in isolation.
 +
 + The same with module unit tests, unit test blocks may selectively
 + be executed. This is achieved by putting a check in place that
 + tests whether the unit test block may be executed or not.
 +
 + ~~~~~~~~~~
 + unittest {
 +   if (abortUnitTestBlock()) return;
 +   ...
 + }
 + ~~~~~~~~~~
 +
 + To negate the behavior, pass a value to the `abortUnitTestBlock`
 + function that evaluates to `false`.
 +/



version (unittest):



import std.container: DList, make;
import core.runtime;
import core.exception: assertHandler, AssertError;



shared static this () {
    assertHandler(&csAssertHandler);
    Runtime.extendedModuleUnitTester = &customModuleUnitTester;
    //includeUnitTest();
}



/++ Color definitions. +/
private
enum Color: string {
    Reset   = "\033[0;;m",
    Red     = "\033[0;31m",
    IRed    = "\033[38;5;160m",
    Green   = "\033[0;32m",
    IGreen  = "\033[38;5;34m",
    Yellow  = "\033[0;93m",
    White   = "\033[0;97m"
}



/++ Container type. +/
alias Container = DList!string;



/++
 + Execution list.
 +
 + A collection of module names that will be allowed to execute its
 + corresponding unit tests.
 +/
 private
 __gshared
Container executionList;

/++ Passed unit test block counter for a module. +/
private
size_t modulePassCounter;

/++ Aborted unit test block counter for a module. +/
private
size_t moduleAbortCounter;

/++ Executed unit test block counter for a module. +/
private
size_t moduleExecuteCounter;



/++
 + Custom module unit test runner.
 +
 + Code snippet from runtime.d.runModuleUnitTests
 + Ref: druntime/src/core/runtime.d
 +/
UnitTestResult
customModuleUnitTester ()
{
    import std.algorithm: startsWith;
    import std.string: tr;
    import std.array: split;

    import std.stdio: writeln;

    import core.stdc.stdio: printf, fflush, stdout;
    import core.exception: AssertError;
    import core.runtime;
    import core.time: MonoTime;

    UnitTestResult result;
    result.passed = 0;
    result.executed = 0;
    size_t totalPassed;
    size_t totalAborted;
    size_t totalExecuted;
    foreach (m; ModuleInfo) {
        if (!m) {
            continue;
        }
        if (isInternalModule(m.name)) {
            continue;
        }
        if (!isIncludedUnitTest(m.name)) {
            version (verbose_unit_test)
            printf("[unittest] Module: %s not tested.\n", m.name.ptr);
            continue;
        }
        auto fp = m.unitTest;
        if (!fp) {
            continue;
        }
        if (m.name) {
            printf("[unittest] Module: %s\n", m.name.ptr);
        }
        modulePassCounter = 0;
        moduleAbortCounter = 0;
        moduleExecuteCounter = 0;
        bool assertionOccurred = false;
        immutable t0 = MonoTime.currTime;
        try {
            fp();
        } catch (Throwable e) {
            if (typeid(e) == typeid(AssertError)) {
                // If assertion is from the unit tested module, do not
                // print the stack trace.
                auto mName = m.name ~ ".d";
                auto fName = e.file;
                debug (verbose) printf("Module:   %s\n", mName.ptr);
                debug (verbose) printf("Filename: %s\n", fName.ptr);
                if (e.file.length == m.name.length) {
                    fName = e.file.tr("/", ".")[$ - mName.length..$];
                } else if (e.file.length < m.name.length) {
                    enum SEPARATOR = ".";
                    //auto arr = mName.split(SEPARATOR);
                }
                if (mName == fName) {
                    continue;
                }
            }
            // When an assertion is caught inside assertThrown(), the
            // message string defaults to null. This can be used to
            // check if an assertion inside assertThrown() was caught.
            // If the assertion was caught, do not report the
            // assertion failure.
            //
            // See std.exception.assertThrown definition.
            if (e.message.length > 0) {
                modulePassCounter--;
                assertionOccurred = true;
                // Display stack trace; indent for alignment only
                foreach (i, item; e.info) {
                    auto info = item.startsWith("/home") ? item[32..$] : item;
                    printf("   [trace] %s\n", info.ptr);
                }
                printf("---------- Trace end\n");
                fflush(stdout);
            }
        } // catch

        printf("             Time: %.3fs\n",
            (MonoTime.currTime - t0).total!"msecs" / 1000.0);
        printf("             Blocks: %ld aborted, %ld executed.\n",
            moduleAbortCounter,
            moduleExecuteCounter);

        totalPassed += modulePassCounter;
        totalAborted += moduleAbortCounter;
        totalExecuted += moduleExecuteCounter;
        if (moduleExecuteCounter > 0) {
            result.executed++;
            if (!assertionOccurred) {
                result.passed++;
            }
        }
    }

    const totalFailed = totalExecuted - totalPassed;

    string passColor = totalPassed == 0 ? Color.IRed : Color.IGreen ;
    string failColor = totalFailed == 0 ? Color.IGreen : Color.IRed ;
    string abortColor = totalAborted == 0 ? Color.IGreen : Color.Yellow ;
    string execColor = totalExecuted == 0 ? Color.IRed : Color.Reset ;

    printf("\n[unittest] Summary: %s%zd passed%s, %s%zd failed%s, %s%zd aborted%s, %s%zd executed%s\n\n",
        passColor.ptr, totalPassed, Color.Reset.ptr,
        failColor.ptr, totalFailed, Color.Reset.ptr,
        abortColor.ptr, totalAborted, Color.Reset.ptr,
        execColor.ptr, totalExecuted, Color.Reset.ptr);

    // NOTE:
    // DMD 2.090.0 changed -unittest behaviour and now defaults to
    // running unit tests only. If old behavious is desired (run tests
    // then main), use --DRT-testmode=run-main.

    // Do not print summary, we handle it here.
    result.summarize = false;
    // Do not run main()
    result.runMain = false;

    return result;
    // End of code snippet from runtime.d.runModuleUnitTests
}



/++ Custom assert handler. +/
void
csAssertHandler (
    string file,
    ulong line,
    string msg
)
nothrow
{
    import core.stdc.stdio: printf, fflush, stdout;
    import core.exception: AssertError;

    // When an assertion is caught inside assertThrown(), the
    // message string defaults to null. This can be used to check
    // if the assertion passed to assertThrown() was caught. If the
    // assertion was caught, do not report the assertion failure.
    //
    // See std.exception.assertThrown definition.
    if (msg.length > 0) {
        printf("---------- Trace start\n");
        printf("[unittest] %sAssertion Failed%s: %.*s (%llu): %.*s\n",
            Color.IRed.ptr,
            Color.Reset.ptr,
            cast(int) file.length,
            file.ptr,
            line,
            cast(int) msg.length,
            msg.ptr);
        fflush(stdout);
    }
    version (D_BetterC) {
        asm nothrow { hlt; }
    } else {
        throw new AssertError(msg);
    }
}



/++
 + Add the module name to the execution list.
 +
 + Returns `true` if the module name has been successfully added to
 + the execution list.
 +/
bool
includeUnitTest (
    const bool include = true,
    const string mod = __MODULE__
) {
    version (execute_all_unit_tests) {
        return false;
    } else {
        if (!include) {
            return false;
        }
        if (!isIncludedUnitTest(mod)) {
            executionList.insert(mod);
            return true;
        } else {
            return false;
        }
    }
}



/++
 + Check the execution list if the module name argument is present.
 +
 + Returns `true` if the module name exists in the execution list.
 +/
bool
isIncludedUnitTest (const string mod)
{
    import std.algorithm: canFind;
    version (execute_all_unit_tests) {
        return true;
    } else {
        return executionList[].canFind(mod);
    }
}
unittest {
    if (abortUnitTestBlock(false)) return;
    bool included = isIncludedUnitTest(__MODULE__);
    version (execute_all_unit_tests) {
        assert(included);
    } else {
        assert(included);
    }
}



/++
 + Determine if the argument is a D language module.
 +
 + Returns `true` if the argument is a D language module.
 +/
private
bool
isInternalModule (const string mod)
{
    import std.algorithm: startsWith;
    return mod.startsWith("__main")
        || mod.startsWith("core")
        || mod.startsWith("etc")
        || mod.startsWith("gc")
        || mod.startsWith("object")
        || mod.startsWith("rt")
        || mod.startsWith("std");
}
unittest {
    if (abortUnitTestBlock(false)) return;
    assert(isInternalModule("__main"));
    assert(isInternalModule("core.submodule"));
    assert(isInternalModule("etc.submodule"));
    assert(isInternalModule("gc.submodule"));
    assert(isInternalModule("gc.submodule"));
    assert(isInternalModule("object.submodule"));
    assert(isInternalModule("rt.submodule"));
    assert(isInternalModule("std.submodule"));
}



/++
 + Abort a unit test block execution by default.
 +
 + To run a single unit test block for debugging, pass a condition
 + that evaluates to `false`.
 +
 + ~~~~~~~~~~
 + unittest {
 +   import spheare.ut;
 +   if (abortUnitTestBlock(false)) return;
 + }
 + ~~~~~~~~~~
 +/
bool
abortUnitTestBlock (
    const string mod = __MODULE__,
    const string func = __FUNCTION__,
    const size_t line = __LINE__
) (
    const bool abort = true
) {
    import core.stdc.stdio: printf, fflush, stdout;
    debug (verbose) import std.stdio: writeln;
    version (execute_all_unit_tests) {
        debug (verbose) writeln("Execute all unit tests.");
        // Assume it passed first
        // If an assertion occurs, then we subtract by 1
        modulePassCounter++;
        moduleExecuteCounter++;
        return false;
    } else {
        bool retval = false;
        if (abort) {
            moduleAbortCounter++;
            version (verbose_unit_test)
            printf("   [block]   @ %ld %saborted%s.\n",
                line - 1,
                Color.Yellow.ptr,
                Color.Reset.ptr);
            retval = true;
        } else {
            // Assume it passed first
            // If an assertion occurs, then we subtract by 1
            modulePassCounter++;
            moduleExecuteCounter++;
            printf("   [block]   @ %ld %sexecuted%s.\n",
                line - 1,
                Color.Green.ptr,
                Color.Reset.ptr);
            retval = false;
        }
        fflush(stdout);
        return retval;
    }
}
unittest {
    import std.exception: assertThrown;
    version (execute_all_unit_tests) {
        assert(!abortUnitTestBlock());
    } else {
        assert(abortUnitTestBlock());
        assert(!abortUnitTestBlock(false));
    }
    version (execute_all_unit_tests) {
        assert(!abortUnitTestBlock());
    } else {
        assertThrown!AssertError(assert(!abortUnitTestBlock()));
    }
}
