/**
 * Excluded module.
 */
module test.selective_module.excluded;

version (unittest) {
    static import test.selective_module.sut_wrapper;
    mixin (test.selective_module.sut_wrapper.exclude);
}

int div (const int arg, const int n) {
    return arg / n;
}
@("div")
unittest {
    mixin (test.selective_module.sut_wrapper.prologue);
    assert (div(10, 1) == 10);
}
