module test.no_wrapper.mul;

import sut;

size_t mul (const int arg, const int n) {
    return arg * n;
}
@("mul")
unittest {
    mixin (unitTestBlockPrologue!()());
    assert (mul(10, 2) == 20);
}
