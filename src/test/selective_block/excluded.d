/**
 * Excluded module.
 */
module test.selective_block.excluded;

version (unittest) {
    static import test.selective_block.sut_wrapper;
    mixin (test.selective_block.sut_wrapper.exclude);
}

int div (const int arg, const int n) {
    return arg / n;
}
@("div")
unittest {
    mixin (test.selective_block.sut_wrapper.prologue);
    assert (div(10, 1) == 10);
}
