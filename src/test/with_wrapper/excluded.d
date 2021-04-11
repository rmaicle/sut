/**
 * Excluded module.
 */
module test.with_wrapper.excluded;

version (unittest) {
    static import test.with_wrapper.sut_wrapper;
    mixin (test.with_wrapper.sut_wrapper.exclude);
}

int div (const int arg, const int n) {
    return arg / n;
}
@("div")
unittest {
    mixin (test.with_wrapper.sut_wrapper.prologue);
    assert (div(10, 1) == 10);
}
