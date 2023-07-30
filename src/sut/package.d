/**
 * Selective Unit Testing (SUT) Module
 *
 * Unit testing library for selective unit test execution of D programs.
 * It allows per module and per unit test block execution.
 *
 * Copyright (c) 2020-2021 Ricardo I. Maicle
 * Distributed under MIT license.
 * See LICENSE file for detail.
 *
 *
 *
 * Package unit testing:
 * Requires that the current directory is at <project>/src/sut.
 *
 *    dmd                               \
 *      -I=../                          \
 *      -i                              \
 *      -main                           \
 *      -debug                          \
 *      -unittest                       \
 *      -version=sut                    \
 *      -version=sut_internal_unittest  \
 *      -run                            \
 *      package.d
 */
module sut;

public import sut.prologue:
    executeBlock,
    getUnitTestName,
    unitTestBlockPrologue;
public import sut.exclude:
    exclusionList,
    excludeModule;
public import sut.counter: unitTestCounter;



version (sut_internal_unittest) {
    version (sut) { } else {
        enum ERR_MSG = `Compiling with version identifier 'sut_internal_unittest'
    requires 'sut' version definition.`;
        static assert (false, ERR_MSG);
    }
}



version (sut) {
    version (D_ModuleInfo):

    static import sut.runtime;

    shared static this () {
        import sut.runner: customUnitTestRunner;
        import core.runtime: Runtime;
        if (!handleArguments(Runtime.args())) {
            sut.runtime.Runtime.exitFlag = true;
        }
        // When Runtime.exitFlag is true, we exit from the unit test runner
        // because we cannot exit here.
        Runtime.extendedModuleUnitTester = &customUnitTestRunner;
    }



    /**
     * Handle run-time arguments. Arguments are passed to the program
     * at compile-time.
     *
     * The function is called statically during module initialization.
     */
    bool
    handleArguments (const string[] arg)
    {
        import sut.config: config;
        import std.getopt:
            getoptConfig = config,
            defaultGetoptPrinter,
            getopt;

        // Necessary to declare a local array variable because
        // getopt function accepts only reference arrays.
        string[] arguments = arg.dup;
        // Temporary variable for filenames of passed arguments
        string[] files;
        auto helpInfo = getopt(
            arguments,
            getoptConfig.passThrough,
            "config|c", "configuration file (../build/unittest.conf)", &files);
        if (helpInfo.helpWanted) {
            defaultGetoptPrinter("SUT command-line options:", helpInfo.options);
            return false;
        }
        // Send out the acquired filenames
        auto filesProcessed = config.collect(files);
        return true;
    }
}
