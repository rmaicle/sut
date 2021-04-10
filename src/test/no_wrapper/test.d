module test.no_wrapper.test;

import sut;                                 // SUT module

int add (const int arg, const int n) {
    return arg + n;
}
@("add")                                    // unit test block name
unittest {
    mixin (unitTestBlockPrologue!()());     // necessary code
    assert (add(10, 1) == 11);
}

int sub (const int arg, const int n) {
    return arg - n;
}
@("subtract")                               // unit test block name
unittest {
    mixin (unitTestBlockPrologue!()());     // necessary code
    assert (sub(10, 1) == 9);
}
