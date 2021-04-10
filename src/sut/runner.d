module sut.runner;

import sut.config: readConfigFile;
import sut.counter:
    moduleCounter,
    UnitTestCounter;
import sut.execlist:
    getExecutionList,
    isInternalModule,
    isLanguageModule,
    isUnitTestBlockExecuted;
import sut.skiplist:
    skipList = moduleList,
    isInSkipList = isFound;
import sut.output:
    printAssertion,
    printIntro,
    printModuleStart,
    printModuleSummary,
    printSummary;

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
    import std.string: join, toStringz;

    import core.runtime;
    import core.stdc.stdio: fflush, printf, stdout;
    import core.time: MonoTime;

    UnitTestResult result;
    result.passed = 0;
    result.executed = 0;

    UnitTestCounter totalCounter;
    size_t moduleCount = 0;
    string[] withUnitTestModules;
    string[] noUnitTestModules;

    void
    appendToNoUnitTestList (const string arg)
    {
        if (!isInSkipList(arg)) {
            noUnitTestModules ~= arg;
        }
    }

    void
    appendToWithUnitTestList (const string arg)
    {
        withUnitTestModules ~= arg;
    }

    debug (verbose) printf("Compiler: %s\n", compilerName.toStringz);

    getExecutionList(readConfigFile);
    printIntro();

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
            appendToNoUnitTestList(m.name);
            continue;
        }
        moduleCounter.reset();
        bool assertionOccurred = false;
        isUnitTestBlockExecuted = false;
        appendToWithUnitTestList(m.name);
        printModuleStart(m.name);
        immutable t0 = MonoTime.currTime;
        try {
            fp();
        } catch (Exception e) {
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
                moduleCounter.revertPassing();
                assertionOccurred = true;
                printAssertion (m.name, e);
                fflush(stdout);
            }
        }

        if (isUnitTestBlockExecuted) {
            printModuleSummary (m.name, moduleCounter, t0, MonoTime.currTime);
        }

        totalCounter.add(moduleCounter);
    }

    printSummary(totalCounter,
        moduleCount,
        withUnitTestModules,
        skipList,
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
