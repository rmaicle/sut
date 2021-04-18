/**
 * Selective Unit Testing (SUT) Module
 *
 * Custom unit testing library for selective unit test execution of D programs.
 *
 * Copyright (c) 2020-2021 Ricardo I. Maicle
 * Distributed under MIT license.
 * See LICENSE file for detail.
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



version (sut) {
    version (D_ModuleInfo):

    static import sut.runtime;

    shared static this () {
        import sut.runner: customUnitTestRunner;
        import core.runtime: Runtime;
        sut.runtime.Runtime.exitFlag = handleArguments(Runtime.args());
        // When Runtime.exitFlag is true, we exit from the unit test runner
        // because we cannot exit here.
        Runtime.extendedModuleUnitTester = &customUnitTestRunner;
    }



    bool
    handleArguments (const string[] arg)
    {
        import sut.config:
            config,
            FileContent;
        import sut.util: unprefix;

        import std.exception: enforce;
        import std.file: exists;
        import std.format: format;
        import std.getopt;
        import std.stdio: writefln;
        import std.string: startsWith;

        enum FILE_NOT_FOUND = "File not found: %s";

        string[] arguments = arg.dup;
        string[] files;
        auto helpInfo = getopt(
            arguments,
            "config|c", "configuration file", &files);
        if (helpInfo.helpWanted) {
            defaultGetoptPrinter("SUT command-line options:", helpInfo.options);
            return false;
        }
        if (files.length == 0) {
            return true;
        }
        foreach (file; files) {
            enforce(file.exists(), format(FILE_NOT_FOUND, file));
            const fileContent = config.readFile(file);
            config.filter(fileContent);
        }
        return true;
    }
}
