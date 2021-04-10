/**
 * Empty unit test module expected to be reported as such
 * in the unit test summary.
 */
module test.selective_module.empty;

version (unittest) {
    static import test.selective_module.sut_wrapper;
    mixin (test.selective_module.sut_wrapper.skip);
}
