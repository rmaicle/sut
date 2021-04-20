/**
 * Module with unit test but not using the prologue code.
 */
module test.selective_module.no_prologue;

size_t square (const uint arg) {
    return arg * arg;
}
unittest {
    assert (square(10) == 100);
}

