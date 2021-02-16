# Selective Unit Testing

A D programming language custom unit test runner that provides selective unit
test execution.
It allows per module and per unit test block execution.



## Rationale

The execution of unit tests in D is an all or nothing approach.
It is necessary to guarantee, in some degree, that the code being compiled
passes all tests.

Development, maintenance, and enhancement of fine-grained details and
components require testing to be performed at a lower level in isolation.
In the context of testing an enhancement involving a single function,
running the default unit test runner will:

  * run unit tests for the modified function
  * run unit tests in the same module
  * run unit tests of other referenced user-defined modules

In this bottom-up scenario, the immediate concern is the first operation.
The other two operations, which incur extra runtime, can be performed after.

Using this module provides the capability to selectively execute unit tests
in a bottom-up approach starting with functions then moving up to modules.



## Compatibility

This module has been tested with the reference compiler DMD version 2.095.

This module cannot be used if D source is not compiled with `ModuleInfo`.
That includes source codes being compiled with the `-betterC` flag since the
flag disables the use of `ModuleInfo`.



## Simplified Example

In this example, the following directory structure is assumed.

~~~
$ tree -L 3
...
`-- src
    |-- sut                     // this module
    |   ...
    `-- test                    // we are here
        |-- test.d              // 1st example
        |-- test_2.d            // using encapsulating module
        |-- using_sut.d         // encapsulating module
        `-- unittest.conf
~~~

Here is the first example using the module.

~~~d
module test;

import sut;                                 // unit test module
import std.stdio: writeln;

int add (const int arg, const int n) {
    return arg + n;
}
@("add")                                    // name used for selection
unittest {
    mixin (unitTestBlockPrologue!()());     // necessary code
    assert (add(10, 1) == 11);
}

int sub (const int arg, const int n) {
    return arg - n;
}
@("subtract")                               // name used for selection
unittest {
    mixin (unitTestBlockPrologue!()());     // necessary code
    assert (sub(10, 1) == 9);
}

int main () {
    enum result = add(10, 5).sub(1);
    assert (result == 14);
    writeln(result);
    return 0;
}
~~~

The necessary code inserted at the top of every unit test block is a `mixin`.
It is expanded to some code that checks whether the unit test block is to be
executed or not along with some collection of runtime statistics which are
reported to the user after execution.

Compile and build the source code above with the following command:

~~~
dmd -I=../ -J=. -i -unittest -version=sut test.d
~~~

The `-J` and `-version=sut` options are discussed in later sections.

The following is the output of running the `test` program.
It shows the module and line numbers of the executed unit tests (8 and 17)
along with a summary.

~~~
$ ./test
[unittest] Mode:    All
[unittest]          test 8:add
[unittest]          test 17:subtract
[unittest]          test - 2 passed, 0 skipped, 2 found - 0.000s

[unittest] Blocks:  2 passed, 0 failed, 0 skipped, 2 found
[unittest] Modules: 1 With, 0 with skipped, 0 without
[unittest]          Modules With Unit Test: 1
[unittest]            test
[unittest]          Modules With Skipped Unit Test: 0
[unittest]          Modules Without Unit Test: 0
~~~



## Testing a Unit Test Block

Using the above code, it is possible to specify which unit test blocks are to
be executed at runtime.
This is specified using the unit test configuration file, `unittest.conf`,
which contains the _unit test block names_ to execute.
Unit test block names are specified as `utb:<name>`.

To execute the `add` unit test block, it must be specified in the unit test
configuration file.

~~~
utb:add
~~~

The following will be the output of running the test program.

~~~
[unittest] Mode:    Selection
[unittest]            block:  dd
[unittest] Module:  test
[unittest]          test 8:add
[unittest]          test - 1 passed, 1 skipped, 2 found - 0.000s

[unittest] Blocks:  1 passed, 0 failed, 1 skipped, 2 found
[unittest] Modules: 1 With, 1 with skipped, 0 without
~~~



## Testing a Module

To run all unit tests of a module, the unit test configuration file may
specify all the unit test block names or just the module name.

~~~
utm:test
~~~

The output will be the same as the initial output above when the unit test
configuration file was empty.



## Encapsulation

The above code assumes that the source files are compiled with the `sut` module.
To allow source code to be compiled without the `sut` module, the inserted codes
must be wrapped inside static conditional statements.
To make the check centralized, it is recommended to put the encapsulation in a
separate module.
The name of the module can be any name so long as it does not, of course,
conflict with any other modules names.

~~~
/**
 * This module is intended to encapsulate the external `sut` module.
 */
module using_sut;                                       // NOTE

version (unittest):

/**
 * Conditionally compile-in the `sut` module.
 */
static if (__traits(compiles, { import sut; })) {
    public import sut;
}

/**
 * Unit test block prologue code.
 */
enum prologue=`
    static if (__traits(compiles, { import sut; })) {
        mixin (using_sut.unitTestBlockPrologue());      // NOTE
    }
`;
~~~

__NOTE__ The mixin uses the name of the module used to encapsulate the `sut`
module. In this case it is `internal.sut`.

To use, `import` the encapsulating module and call `mixin` with
`using_sut.prologue` argument.

~~~
version (unittest) static import using_sut;
...
mixin (using_sut.prologue);
~~~



## Version Identifier `sut`

To use the module, the version identifier `sut` must be passed to the compiler.
It is used by the `sut` module for some static checks.

~~~
dmd -version=sut
~~~



## Unit Test Configuration File

The unit test configuration file, _unittest.conf_, contains all unit test
block and module names that will be executed.

Formatting:

* one item per line
* unit test block names are prefixed with `utb:`
* module names are prefixed with `utm:`
* names cannot have whitespace
* empty lines and duplicates are ignored

~~~
utb:<unit_test_block_name>
utb:...
utm:<module_name>
utm:...
~~~

The configuration file directory must be specified to the compiler using the
`-J` option.
This commandline option tells the compiler where to look for `string imports`.

~~~
dmd -J=<directory> ...
ldc -J=<directory> ...
~~~



## Change Log

The detailed log of changes can be seen on [CHANGELOG.md](CHANGELOG.md) file.



## License

See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
