module test.with_wrapper.test;

import test.with_wrapper.empty;
version (unittest) {
    static import test.with_wrapper.sut_wrapper;        // changed
}

int add (const int arg, const int n) {
    return arg + n;
}
@("add")
unittest {
    mixin (test.with_wrapper.sut_wrapper.prologue);     // changed
    assert (add(10, 1) == 11);
}

int sub (const int arg, const int n) {
    return arg - n;
}
@("subtract")
unittest {
    mixin (test.with_wrapper.sut_wrapper.prologue);     // changed
    assert (sub(10, 1) == 9);
}
