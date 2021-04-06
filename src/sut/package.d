/**
 * Selective Unit Testing (SUT) Module
 *
 * A D programming language custom unit test runner that allows selective unit
 * test execution.
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
public import sut.skiplist:
    addToPackageList,
    skipPackage;



version (D_ModuleInfo):

shared static this () {
    import sut.runner;
    import core.runtime: Runtime;
    Runtime.extendedModuleUnitTester = &customUnitTestRunner;
}
