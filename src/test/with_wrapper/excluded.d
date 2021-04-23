/**
 * Excluded module.
 */
module test.with_wrapper.excluded;

version (unittest) {
    static import test.with_wrapper.sut_wrapper;        // import
    mixin (test.with_wrapper.sut_wrapper.exclude);      // exclude module
}

int div (const int arg, const int n) {
    return arg / n;
}
@("div")
unittest {
    mixin (test.with_wrapper.sut_wrapper.prologue);     // prologue code
    assert (div(10, 1) == 10);                          // never executed
}
