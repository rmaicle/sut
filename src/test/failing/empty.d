/**
 * Empty unit test module expected to be reported as such
 * in the unit test summary.
 */
module test.failing.empty;

version (unittest) {
    static import test.failing.sut_wrapper;
    mixin (test.failing.sut_wrapper.skip);
}
