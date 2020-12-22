module sut.runner;

import sut.config: UNITTEST_CONFIG_FILE;
import sut.counter: moduleCounter, UnitTestCounter;
import sut.execlist:
    getExecutionList,
    isInternalModule,
    isLanguageModule,
    isUnitTestBlockExecuted;
import sut.output;

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
    import std.compiler: compilerName = name;
    import std.string: toStringz;

    import core.runtime;
    import core.stdc.stdio: fflush, printf, stdout;
    import core.time: MonoTime;

    UnitTestResult result;
    result.passed = 0;
    result.executed = 0;

    UnitTestCounter totalCounter;
    size_t moduleCount = 0;
    string[] withUnitTestModules;
    string[] skippedModules;
    string[] noUnitTestModules;

    debug (verbose) printf("Compiler: %s\n", compilerName.toStringz);

    getExecutionList!(import(UNITTEST_CONFIG_FILE))();
    printUnitTestMode();

    foreach (m; ModuleInfo) {
        if (!m) {
            continue;
        }
        if (isLanguageModule(m.name)) {
            continue;
        }
        if (isInternalModule(m.name)) {
            continue;
        }
        moduleCount++;
        auto fp = m.unitTest();
        if (!fp) {
            noUnitTestModules ~= m.name;
            continue;
        }
        moduleCounter.reset();
        bool assertionOccurred = false;
        isUnitTestBlockExecuted = false;
        // printModuleStart(m.name);
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
                moduleCounter.pass--;
                moduleCounter.fail++;
                assertionOccurred = true;
                printAssertion (m.name, e);
                fflush(stdout);
            }
        }

        if (moduleCounter.pass) {
            withUnitTestModules ~= m.name;
        }
        if (isUnitTestBlockExecuted) {
            printModuleSummary (m.name, moduleCounter, t0, MonoTime.currTime);
        }

        totalCounter.pass += moduleCounter.pass;
        totalCounter.fail += moduleCounter.fail;
        totalCounter.skip += moduleCounter.skip;
        totalCounter.found += moduleCounter.found;

        if (moduleCounter.allSkipped || moduleCounter.someSkipped) {
            skippedModules ~= m.name;
        }
    } // foreach

    printSummary(totalCounter,
        moduleCount,
        withUnitTestModules,
        skippedModules,
        noUnitTestModules);

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
        //auto arr = mName.split(SEPARATOR);
    }
    return mName == fName;
}
