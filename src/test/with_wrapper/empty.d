/**
 * Empty unit test module expected to be reported as such
 * in the unit test summary.
 */
module test.with_wrapper.empty;

version (unittest) {
    static import test.with_wrapper.sut_wrapper;
    mixin (test.with_wrapper.sut_wrapper.skip);
}
