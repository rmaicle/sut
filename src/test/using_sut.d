/**
 * This module is intended to encapsulate the external `sut` module.
 */
module using_sut;                                       // NOTE

version (unittest):

/**
 * Conditionally compile-in the `sut` module.
 */
static if (__traits(compiles, { import sut; })) {
    public import sut;
}

/**
 * Unit test block prologue code.
 */
enum prologue=`
    static if (__traits(compiles, { import sut; })) {
        mixin (using_sut.unitTestBlockPrologue());      // NOTE
    }
`;
