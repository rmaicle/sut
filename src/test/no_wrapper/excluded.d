/**
 * Excluded module.
 */
module test.no_wrapper.excluded;

import sut;
mixin (excludeModule!()());

int div (const int arg, const int n) {
    return arg / n;
}
@("div")
unittest {
    mixin (unitTestBlockPrologue!()());
    assert (div(10, 1) == 10);
}
