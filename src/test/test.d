module test;

import sut;
import std.stdio: writeln;

int add (const int arg, const int n) {
    return arg + n;
}
@("add")
unittest {
    mixin (unitTestBlockPrologue!()());
    assert (add(10, 1) == 11);
}

int sub (const int arg, const int n) {
    return arg - n;
}
@("subtract")
unittest {
    mixin (unitTestBlockPrologue!()());
    assert (sub(10, 1) == 9);
}

void main () {
    enum result = add(10, 5).sub(1);
    assert (result == 14);
    writeln(result);
}
