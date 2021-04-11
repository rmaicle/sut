module test.with_wrapper.mul;

version (unittest) {
    static import test.with_wrapper.sut_wrapper;        // changed
}

size_t mul (const int arg, const int n) {
    return arg * n;
}
@("mul")
unittest {
    mixin (test.with_wrapper.sut_wrapper.prologue);     // changed
    assert (mul(10, 2) == 20);
}
