module test.selective_module.test;

import test.selective_module.excluded;
import test.selective_module.no_unittest;
import test.selective_module.mod_add;
import test.selective_module.mod_sub;
import test.selective_module.mod_mul;

version (unittest) {
    static import test.selective_module.sut_wrapper;
    mixin (test.selective_module.sut_wrapper.exclude);
}
