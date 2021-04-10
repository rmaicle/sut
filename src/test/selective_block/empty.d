/**
 * Empty unit test module expected to be reported as such
 * in the unit test summary.
 */
module test.selective_block.empty;

version (unittest) {
    static import test.selective_block.sut_wrapper;
    mixin (test.selective_block.sut_wrapper.skip);
}
