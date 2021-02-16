module test;

version (unittest) static import using_sut;
import std.stdio: writeln;

int add (const int arg, const int n) {
    return arg + n;
}
@("add")
unittest {
    mixin (using_sut.prologue);
    assert (add(10, 1) == 11);
}

int sub (const int arg, const int n) {
    return arg - n;
}
@("subtract")
unittest {
    mixin (using_sut.prologue);
    assert (sub(10, 1) == 9);
}

void main () {
    enum result = add(10, 5).sub(1);
    assert (result == 14);
    writeln(result);
}
