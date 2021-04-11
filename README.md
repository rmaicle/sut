# Selective Unit Testing

Custom unit testing library for selective unit test execution of D programs.
It allows per module and per unit test block execution.



## Rationale

The default unit test execution in D is all or nothing.
It is designed to ensure that all source codes being compiled passes all tests.
What it does not address is isolated testing of individual unit tests and
modules.

I believe that allowing execution of specific tests complements the all or
nothing approach by providing a middle ground.
It aids the programmer to focus on the detail at hand.
The programmer can try and test the concerned unit as often as necessary,
without being untimely bothered by broken tests from other parts of the code
base.

Also, being able to test a unit in isolation saves CPU performance and time.
The fast turn around may become an encouragement to do more experiments, craft
better tests, and be more productive.

This module is an attempt to provide greater unit testing flexibility and
capability.



## Features

The selective unit testing module provides the programmer the ability to run
specific tests during development, maintenance, and enhancement efforts.
It also allows the programmer to opt-out and revert to the default unit test
execution.



#### Unit Test Block Execution

The programmer can choose to execute a specific unit test block or a group of
unit test blocks that is of immediate concern.
This helps the programmer to focus on the _unit_ without being bothered by
other unit tests that may fail.



#### Module Unit Test Execution

The programmer can also choose to execute unit tests inside a module, also
without being flooded with failed tests from other modules.



#### Module Exclusion

The library also allow modules to be excluded from unit test execution.
This is the opposite of the _Module Unit Test Execution_.

These feature is a consequence of determining which modules do not have unit
tests.
Packages that simply declare public imports are candidates for this.
It is desirable to know that such modules are explicitly identified in the
unit testing report as a guide.


#### Detailed Report

The library provides a detailed report of the unit test execution.

* Reports the line number and _name_ of executed unit test blocks;
* Summary of successful and failed unit test blocks per module;
* Summary of all successful and failed unit test blocks;
* List of modules with unit tests;
* List of excluded modules from unit testing;
* List of modules without unit tests.



## Compatibility

This module has been tested with the reference compiler DMD version 2.095.

This module cannot be used if D source is not compiled with `ModuleInfo`.
That includes source codes being compiled with the `-betterC` flag since the
flag disables the use of `ModuleInfo`.



## Usage



### Version Identifier

To use the module, the version identifier `sut` must be passed to the compiler.
It is used by the `sut` module for conditional compilation and static checks.

~~~
$ dmd -version=sut
$ ldc --d-version=sut
~~~


### Functions

The `sut` module provides the following functions to be used in a
[`mixin`](https://dlang.org/spec/statement.html#mixin-statement) statement.



#### unitTestBlockPrologue

This function is called as the first line inside the unit test block.
The code controls whether to continue execution or return early from
the block along with some code that collects information about the unit test
block.

The code looks for a
[`user-defined attribute`](https://dlang.org/spec/attribute.html#uda)
(UDA) for the unit test block and uses the first UDA string as the _unit test
block name_.
If it cannot find one, it uses the compiler-generated unit test block identifier
as the _unit test block name_.
It is advised to use a UDA string to allow better identification of unit test
blocks when using _selective unit test block_ execution.
See the _Unit Test Configuration File_ section below on how to use this feature.

~~~d
@("some name")
unittest {
    mixin (unitTestBlockPrologue!()());
    ...
}
~~~



#### excludeModule

This is the function used to declare modules to be explicitly excluded
from any unit test execution.

~~~d
mixin (excludeModule!()());                 // exclude module code
~~~



### Unit Test Configuration File

The unit test configuration file, _unittest.conf_, contains all unit test
block and module names to be executed.
If the _unit test configuration file_ is empty, then all unit test blocks and
modules are executed except for modules declared to be excluded using
`excludeModule`.

Note that the _unit test configuration file_ must always exist.

Formatting:

* one item per line
* unit test block names are prefixed with `utb:`
* unit test block names can contain space
* module names are prefixed with `utm:`
* module names cannot contain spaces
* empty lines and duplicates are ignored

~~~
utb:<unit_test_block_name>
utb:...
utm:<module_name>
utm:...
~~~

The directory where the _unit test configuration file_ exists must be
specified to the compiler usin gthe `-J` command-line option.
The `-J` command-line option tells the compiler where to look for files for
_import expressions_.

~~~
dmd -J=<directory> ...
ldc -J=<directory> ...
~~~



#### Unit Test Block Names

Unit test block names are compared with the unit test block entries in the
_unit test configuration file_.
The unit test block is executed if the name in the _unit test configuration
file_ matches exactly or is the beginning of the _unit test block name_.
Otherwise, it is 'skipped'.

An example using the following _unit test block names_.

~~~d
@("func one")
...
@("func two")
...
@("func three")
~~~

If the _unit test configuration file_ contains `utb:func t`, then the unit
test blocks for `@("func two")` and `@("func three")` are executed.
The unit test block for `@("func one")` will be 'skipped'.



## SUT Wrapper Module

It is necessary for the client code to 'wrap' the usage of `sut` module inside
another module so the client code can opt-out and use the default unit test
execution without deleting the `sut` code.
This _wrapper module_ will contain the necessary
[`conditional compilation`](https://dlang.org/spec/version.html)
code to achieve this capability.

~~~d
module sut_wrapper;

version (sut) {
    static if (__traits(compiles, { import sut; })) {
        /**
         * Conditionally compile-in the `sut` module if it is visible in
         * the client code. Otherwise, it does nothing.
         */
        pragma (msg, "Using selective unit testing module.");
        public import sut;

        /**
         * Unit test block prologue code mixed-in from unit test blocks.
         */
        enum prologue=`mixin (sut_wrapper.unitTestBlockPrologue);`;
        enum exclude=`mixin (sut_wrapper.excludeModule);`;
    } else {
        pragma (msg, "Version identifier 'sut' defined but 'sut' module not found.");
        enum prologue="";
        enum exclude="";
    }
} else {
    pragma (msg, "Using default unit test runner.");
    enum prologue="";
    enum exclude="";
}
~~~

The primary concern here is the _module name_ and in this case `sut_wrapper`.
The _wrapper module_ name must be the module name prefixing the call to
`unitTestBlockPrologue` and `excludeModule` as shown below.

~~~d
enum prologue=`mixin (sut_wrapper.unitTestBlockPrologue);`;
enum exclude=`mixin (sut_wrapper.excludeModule);`;
~~~

This is because the client code imports the _wrapper module_ statically.
It is possible not to import it statically but to avoid name conflicts,
statically importing the module is a safer choice.

The client code that uses this module should look like the code below.

~~~d
version (unittest) {
    static import sut_wrapper;
}

@("add")
unittest {
    mixin (sut_wrapper.prologue);
    ...
}
~~~



## Basic Example

Let us begin with the _with_wrapper_ example to demonstrate the use of the library,
show what it is capable, and display a console output.
This example has four D source files

The `unittest.conf` file is empty for this example.

* _test.d_ - main file with unit tests
* _mul.d_ - module with a unit test to demonstrate reporting output
* _excluded.d_ - shows how modules can be excluded from unit test execution
* _no_unittest.d_ - module without a unit test to demonstrate reporting output

The following are the contents of each file starting with the main file.

* __test.d__

  ~~~d
  module test.with_wrapper.test;

  import test.with_wrapper.mul;
  import test.with_wrapper.excluded;
  import test.with_wrapper.no_unittest;
  version (unittest) {
      static import test.with_wrapper.sut_wrapper;        // import wrapper module
  }

  int add (const int arg, const int n) {
      return arg + n;
  }
  @("add")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // unit test block prologue
      assert (add(10, 1) == 11);
  }

  int sub (const int arg, const int n) {
      return arg - n;
  }
  @("sub")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // unit test block prologue
      assert (sub(10, 1) == 9);
  }
  ~~~

* __mul.d__

  ~~~d
  module test.with_wrapper.mul;

  version (unittest) {
      static import test.with_wrapper.sut_wrapper;        // import wrapper module
  }

  size_t mul (const int arg, const int n) {
      return arg * n;
  }
  @("mul")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // unit test block prologue
      assert (mul(10, 2) == 20);
  }
  ~~~

* __excluded.d__

  ~~~d
  module test.with_wrapper.excluded;

  version (unittest) {
      static import test.with_wrapper.sut_wrapper;        // import wrapper module
      mixin (test.with_wrapper.sut_wrapper.exclude);      // exclude module
  }

  int div (const int arg, const int n) {
      return arg / n;
  }
  @("div")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // unit test block prologue
      assert (div(10, 1) == 10);                          // never executed
  }
  ~~~

* __no_unittest.d__

  ~~~d
  /**
   * Module without unit test.
   */
  module test.with_wrapper.no_unittest;                   // reported; without unit tests
  ~~~

Compile the source codes and run the unit tests with `../compile.sh test.d`.

~~~
Using selective unit testing module.
[unittest] Start    2021-Apr-11 22:44:14.5680752
[unittest] Mode:    All
[unittest] Module:  test.with_wrapper.test   14 add
[unittest]          test.with_wrapper.test   23 sub
[unittest]          test.with_wrapper.test - 2 passed, 0 failed, 2 found - 0.000s
[unittest] Module:  test.with_wrapper.mul   11 mul
[unittest]          test.with_wrapper.mul - 1 passed, 0 failed, 1 found - 0.000s

[unittest] Summary: 3 passed, 0 failed, 3 found
[unittest]          2 module(s) with unit test
[unittest]          1 module(s) without unit test
[unittest]          1 module(s) excluded
[unittest] List:    Module(s) with unit test (2)
[unittest]              test.with_wrapper.mul
[unittest]              test.with_wrapper.test
[unittest] List:    Module(s) without unit test (1)
[unittest]              test.with_wrapper.no_unittest
[unittest] List:    Module(s) excluded (1)
[unittest]              test.with_wrapper.excluded
[unittest] End      2021-Apr-11 22:44:14.5682216
~~~



## Selective Unit Test Block Execution Example

Edit the _unit test configuration file_ and add an entry; choose one of:

* `utb:add`
* `utb:sub`
* `utb:mul`

Compile the source codes and run the unit tests with `../compile.sh test.d`.

Choosing `utb:add` shows the following output:

~~~d
Using selective unit testing module.
[unittest] Start    2021-Apr-12 02:49:09.8951581
[unittest] Mode:    Selection
[unittest]            block:  add
[unittest] Module:  test.selective_block.test   14 add
[unittest]          test.selective_block.test - 1 passed, 0 failed, 2 found - 0.000s

[unittest] Summary: 1 passed, 0 failed, 3 found
[unittest]          2 module(s) with unit test
[unittest]          1 module(s) without unit test
[unittest]          1 module(s) excluded
[unittest] List:    Module(s) with unit test (2)
[unittest]              test.selective_block.mul
[unittest]              test.selective_block.test
[unittest] List:    Module(s) without unit test (1)
[unittest]              test.selective_block.no_unittest
[unittest] List:    Module(s) excluded (1)
[unittest]              test.selective_block.excluded
[unittest] End      2021-Apr-12 02:49:09.8955033
~~~






## Test Programs

The repository contains test source codes that are good enough to demonstrate
how to use the `sut` module.
The directory structure below shows where these test source codes are located
in the repository.
You can download or clone the repository and run the tests.

~~~
...
`-- src
    |-- sut                     // this module
    |   ...
    `-- test                    // we are here
        |-- failing             // test with failed assertion
        |-- no_wrapper          // test of not using a 'wrapper' module
        |-- selective_block     // test of selective unit test block execution
        |-- selective_module    // test of selective module execution
        |-- with_wrapper        // test of using a 'wrapper' module
        `-- compile.sh          // compile script
~~~



## Change Log

The detailed log of changes can be seen on [CHANGELOG.md](CHANGELOG.md) file.



## License

See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
