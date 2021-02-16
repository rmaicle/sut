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



version (unittest):

public import sut.prologue:
    executeUnitTestBlock,
    getUTNameFunc,
    unitTestBlockPrologue;

import sut.runner;

import core.runtime: Runtime;

version (sut) {
    version (D_ModuleInfo) {
        version = sut_with_module_info;
    }
}

version (sut_with_module_info):

shared static this () {
    Runtime.extendedModuleUnitTester = &customUnitTestRunner;
}
