module test;

import sut;                                 // SUT module
import std.stdio: writeln;

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
    assert (sub(10, 1) == 0);
}

int main () {
    enum result = add(10, 5).sub(1);
    assert (result == 14);
    writeln(result);
    return 0;
}
