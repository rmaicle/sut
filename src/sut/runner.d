module sut.runner;

import sut.config: config;
import sut.counter: unitTestCounter;
import sut.execution: executionList;
import sut.exclude: exclusionList;
import sut.output:
    printAssertion,
    printIntro,
    printModuleSummary,
    printSummary,
    printUnknownSelections;
import sut.runtime: Runtime;

import core.exception: AssertError;
import core.runtime: UnitTestResult;

debug import std.stdio;



/**
 * Custom module unit test runner.
 *
 * Code snippet from runtime.d.runModuleUnitTests
 * Ref: druntime/src/core/runtime.d
 */
UnitTestResult
customUnitTestRunner ()
{
    import std.string: join, toStringz;

    import core.stdc.stdio: fflush, printf, stdout;
    import core.time: MonoTime;

    UnitTestResult result;
    result.passed = 0;
    result.executed = 0;
    if (Runtime.exitFlag) {
        return result;
    }

    executionList.unittests = config.unittests;
    executionList.modules = config.modules;
    {
        scope (exit) config.reset();
        printIntro();
        printUnknownSelections(config);
    }

    foreach (m; ModuleInfo) {
        if (!m) {
            continue;
        }
        if (isExcludedModule(m.name)) {
            continue;
        }
        auto fp = m.unitTest();
        if (!fp) {
            if (!exclusionList.isFound(m.name)) {
                unitTestCounter.modulesWithout ~= m.name;
            }
            continue;
        }
        bool assertionOccurred = false;
        unitTestCounter.modulesWith ~= m.name;
        immutable t0 = MonoTime.currTime;
        try {
            fp();
        } catch (Throwable e) {
            // If assertion is from this module, do not print the stack trace.
            if (typeid(e) == typeid(AssertError)) {
                if (isInternalAssertion(m.name, e.file)) {
                    continue;
                }
            }
            // When an assertion is caught inside assertThrown(), the message
            // string defaults to null. This can be used to check if an
            // assertion inside assertThrown() was caught. If the assertion
            // was caught, do not report the assertion failure.
            //
            // See std.exception.assertThrown definition.
            if (e.message.length > 0) {
                if (unitTestCounter.unitTestBlock.isIn()) {
                    unitTestCounter.current.revertPassing();
                }
                assertionOccurred = true;
                printAssertion (m.name, e);
            }
        }
        if (unitTestCounter.current.isSomeExecuted()) {
            printModuleSummary (m.name, unitTestCounter, t0, MonoTime.currTime);
        }
        unitTestCounter.accumulate();

    }

    printSummary(unitTestCounter, exclusionList.list);

    // NOTE:
    // DMD 2.090.0 changed -unittest behavior and now defaults to
    // running unit tests only. If old behavior is desired (run tests
    // then main), use --DRT-testmode=run-main.

    // Do not print summary, we handle it here.
    result.summarize = false;
    // Do not run main()
    result.runMain = false;

    return result;
    // End of code snippet from runtime.d.runModuleUnitTests
}



bool
isInternalAssertion (
    const string moduleName,
    const string filename
) {
    import std.string: toStringz, tr;

    string mName = moduleName ~ ".d";
    string fName = filename;
    debug (verbose) {
        printf("Module:   %s\n", mName.toStringz);
        printf("Filename: %s\n", fName.toStringz);
    }
    if (filename.length == moduleName.length) {
        fName = filename.tr("/", ".")[$ - moduleName.length..$];
    } else if (filename.length < moduleName.length) {
        enum SEPARATOR = ".";
    }
    return mName == fName;
}



private:



bool
isExcludedModule (const string arg)
{
    return isLanguageModule(arg)
        || isInternalModule(arg)
        || exclusionList.isFound(arg);
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
 * Determine whether the string argument is equal to the package name `sut`.
 * This check is only performed when unit testing is enabled and the
 * version identifier `sut` is not defined.
 *
 * Returns: `true` if the string argument is equivalent to this module's name.
 */
bool
isInternalModule (const string arg)
{
    import std.algorithm: canFind;
    version (sut_internal_unittest) {
        version (sut) {
            // We are testing the `sut` package so we explicitly
            // tell the calling routine that the string argument
            // is not an internal module whatever its value may be.
            return false;
        } else {
            assert (false, `This should be unreachable.
Compiling with version identifier 'sut_internal_unittest'
requires 'sut' version definition.`);
        }
    } else {
        if (arg.canFind(".")) {
            return arg.canFind("sut.") || arg.canFind(".sut");
        } else {
            return arg.canFind("sut");
        }
    }
}
@("isInternalModule")
unittest {
    //mixin (unitTestBlockPrologue());
    version (sut_internal_unittest) {
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
