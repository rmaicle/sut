# Selective Unit Testing

A D programming language custom unit test runner that provides selective unit
test execution.
It allows per module and per unit test block execution.



## Rationale

Execution of unit tests in D is an all or nothing approach.
It is designed to ensure that all source codes being compiled passes all
unit tests.
If there was a change in some part of the code, the unit test should catch
anything that breaks.

Development, maintenance, or enhancements require testing at the lowest level
and in isolation.
In the context of testing an enhancement involving a single function,
running the default unit test runner will:

  * run all unit tests for the modified function
  * run all unit tests of the module
  * run all unit tests of other referenced user-defined modules

That is a lot of runtime overhead when the concern is primarily the
functionality of the function involved.

I believe that allowing execution of specific tests complements the all or
nothing approach by providing a middle ground.
It aids the programmer to focus on the detail at hand, try and test as often as
necessary, without being untimely bothered by other breaking tests.
This would also help the programmer incrementally code functionality and write
tests for that functionality.

code and partially test which
helps in
It also saves CPU resources and time in the edit-test cycle.

This module is an attempt to provide greater unit testing flexibility and
capability.




## Minimum Example

In this example, we use the following directory structure that exists in the
repository.

~~~
$ tree -L 3
...
`-- src
    |-- sut                     // this module
    |   ...
    `-- test                    // we are here
        |-- test.d              // minimum example
        |-- test_2.d            // using encapsulating module example
        |-- using_sut.d         // encapsulating module
        `-- unittest.conf       // SUT unit test configuration file
~~~

Here is the code for the minimal example.

~~~d
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
    assert (sub(10, 1) == 9);
}

int main () {
    enum result = add(10, 5).sub(1);
    assert (result == 14);
    writeln(result);
    return 0;
}
~~~

The _[mixin](https://dlang.org/spec/statement.html#mixin-statement)_ code
`mixin (unitTestBlockPrologue!()())` at the top of every unit test block is
necessary as it is the control mechanism for the continuation of execution or
an early return.
It is also used to collect information for reporting.

Compile and build the source above using the following command:

~~~
$ dmd -I=../ -J=. -i -unittest -version=sut test.d
~~~

The `-J` and `-version=sut` options are discussed in later sections.

The following is the output of running the `test` program.
It shows the module and line numbers of the executed unit tests (10 and 19)
along with a summary.

~~~
$ ./test
[unittest] Mode:    All
[unittest]          test   10 add
[unittest]          test   19 subtract
[unittest]          test - 2 passed, 0 skipped, 2 found - 0.000s

[unittest] Blocks:  2 passed, 0 failed, 0 skipped, 2 found
[unittest] Modules: 1 With, 0 with skipped, 0 without
[unittest]          Modules With Unit Test: 1
[unittest]            test
[unittest]          Modules With Skipped Unit Test: 0
[unittest]          Modules Without Unit Test: 0
~~~



## Unit Test Block Execution

Using the above code, it is possible to specify which unit test blocks are to
be executed.

_Unit test block names_ are _[user-defined attributes](https://dlang.org/spec/attribute.html#uda)_.
They are used to give unit test blocks a more comprehensible name than the
compiler-generated unit test identifiers.

In the minimum example above, there are two unit test block names defined:

  * add - defined at line 9
  * subtract - defined at line 18

To execute only the `add` unit test block, it must be specified in the unit test
configuration file, `unittest.conf`.

~~~
utb:add
~~~

To demonstrate that the other unit test block is not executed, change the
`assert` statement in the `substract` unit test block to fail, like the
following code:

~~~d
assert (sub(10, 1) == 0);
~~~

The following output is displayed after compiling and running the test program.
Note that the assertion did not fail because it was never executed.

~~~
[unittest] Mode:    Selection
[unittest]            block:  add
[unittest] Module:  test
[unittest]          test   10 add
[unittest]          test - 1 passed, 1 skipped, 2 found - 0.000s

[unittest] Blocks:  1 passed, 0 failed, 1 skipped, 2 found
[unittest] Modules: 1 With, 1 with skipped, 0 without
~~~

See the _Unit Test Configuration File_ section below.



## Unit Testing a Module

To run all unit tests inside a module, the unit test configuration file may be
specified with all the unit test block names of the module or just specify the
module name.

~~~
utm:test
~~~

The following output is displayed after compiling and running the test program.

~~~d
[unittest] Mode:    Selection
[unittest]            module: test
[unittest] Module:  test
[unittest]          test   10 add
[unittest]          test   19 subtract
[unittest]          test - 2 passed, 0 skipped, 2 found - 0.000s

[unittest] Blocks:  2 passed, 0 failed, 0 skipped, 2 found
[unittest] Modules: 1 With, 0 with skipped, 0 without
~~~



## SUT module Conditional Compilation

The minimal example code above assumes that the source files are compiled with
the `sut` module.
It is possible to not use the `sut` module without deleting the _mixin_ code.
This is achieved by using _[conditional compilation](https://dlang.org/spec/version.html)_
features of the D language.

To do this, we need to create a module that will contain the conditional
compilation code.

~~~d
/**
 * This module is only to conditionally compile-in the use of `sut` module.
 */
module using_sut;                                                       // NOTE

version (sut) {
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
            mixin (using_sut.unitTestBlockPrologue!(__LINE__ - 2)());   // NOTE
        }
    `;
} else {
    enum prologue="";
}
~~~

__NOTE__ The _[mixin](https://dlang.org/spec/statement.html#mixin-statement)_
statement uses the name of the created module, _using_sut_, to call the
function `unitTestBlockPrologue` defined in the `sut` module.

To use this module, `import` it into other modules and call `mixin` with
`using_sut.prologue` argument.

~~~d
version (unittest) static import using_sut;
...
mixin (using_sut.prologue);
~~~

The minimal example above will now look like the following code.

~~~d
module test;

version (unittest) static import using_sut; // changed
import std.stdio: writeln;

int add (const int arg, const int n) {
    return arg + n;
}
@("add")
unittest {
    mixin (using_sut.prologue);             // changed
    assert (add(10, 1) == 11);
}

int sub (const int arg, const int n) {
    return arg - n;
}
@("subtract")
unittest {
    mixin (using_sut.prologue);             // changed
    assert (sub(10, 1) == 9);
}

int main () {
    enum result = add(10, 5).sub(1);
    assert (result == 14);
    writeln(result);
    return 0;
}
~~~

The above code is in the repository under the file `test_2.d`.
To compile and run it using the `sut` module, execute the same command but
passing the `test_2.d` file to the compiler.

~~~
$ dmd -I=../ -J=. -i -unittest -version=sut test_2.d
~~~

To compile and run it without using the `sut` module, use the following command:

~~~
$ dmd -I=../ -i -unittest test_2.d
~~~



## Version Identifier `sut`

To use the module, the version identifier `sut` must be passed to the compiler.
It is used by the `sut` module for conditional compilation and static checks.

~~~
$ dmd -version=sut
$ ldc --d-version=sut
~~~



## Unit Test Configuration File

The unit test configuration file, _unittest.conf_, contains all unit test
block and module names that will be executed.

Formatting:

* one item per line
* unit test block names are prefixed with `utb:`
* module names are prefixed with `utm:`
* names can contain space
* empty lines and duplicates are ignored

~~~
utb:<unit_test_block_name>
utb:...
utm:<module_name>
utm:...
~~~

The configuration file directory must be specified to the compiler using the
`-J` option.
The `-J` command-line option tells the compiler where to look for files for
_import expressions_.

~~~
dmd -J=<directory> ...
ldc -J=<directory> ...
~~~



## Compatibility

This module has been tested with the reference compiler DMD version 2.095.

This module cannot be used if D source is not compiled with `ModuleInfo`.
That includes source codes being compiled with the `-betterC` flag since the
flag disables the use of `ModuleInfo`.



## Change Log

The detailed log of changes can be seen on [CHANGELOG.md](CHANGELOG.md) file.



## License

See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
