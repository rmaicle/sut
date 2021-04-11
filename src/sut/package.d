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

version (sut) {
    version (D_ModuleInfo):

    shared static this () {
        import sut.runner;
        import core.runtime: Runtime;
        Runtime.extendedModuleUnitTester = &customUnitTestRunner;
    }
}
