/**
 * Module that encapsulates the inclusion of the selective unit test
 * module at compile-time. It allows client code to be compiled with
 * or without using the selective unit test module.
 */
module sut.wrapper;

version (sut) {
        /**
         * Conditionally compile-in the `sut` internal modules necessary.
         */
        public import sut.prologue:
            executeBlock,
            getUnitTestName,
            unitTestBlockPrologue;
        public import sut.exclude:
            exclusionList,
            excludeModule;
        /**
         * Unit test block prologue code mixed-in from unit test blocks.
         */
        enum prologue=`mixin (sut.wrapper.unitTestBlockPrologue);`;
        enum exclude=`mixin (sut.wrapper.excludeModule);`;
} else {
    enum prologue="";
    enum exclude="";
}
