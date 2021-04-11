/**
 * Excluded module.
 */
module test.no_wrapper.excluded;

import sut;                                 // SUT module
mixin (excludeModule!()());                 // exclude module code

int div (const int arg, const int n) {
    return arg / n;
}
@("div")                                    // unit test block name
unittest {
    mixin (unitTestBlockPrologue!()());     // necessary code
    assert (div(10, 1) == 10);
}
