/**
 * This module is only to conditionally compile-in the use of `sut` module.
 */
module using_sut;                                                       // NOTE

version (sut) {
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
            mixin (using_sut.unitTestBlockPrologue!(__LINE__ - 2)());   // NOTE
        }
    `;
} else {
    enum prologue="";
}
