# Selective Unit Testing

Unit testing library for selective unit test execution of D programs.
It allows per module and per unit test block execution.



## Rationale

The default unit test execution in D is all or nothing.
That means all unit tests are executed every time.
It is designed to ensure that all tests pass.
What it does not address is the isolated testing of individual unit tests and
modules.

It is common that modifications, enhancements, refactorings, or
reimplementations of a portion of a code base require the testing of only the
concerned portion.
At this point, the programmer is not yet concerned about integration.
That comes after when the portion of the code has been tested to execute as
expected.
This is the missing part--a unit testing capability supporting the bottom-up
approach.

I believe that allowing execution of specific tests complements the all or
nothing approach by providing a middle ground.
It will aid the programmer to focus on the detail at hand.
The programmer can try and test the concerned parts as often as necessary,
without being untimely bothered by broken tests from other parts of the code
base.

Also, being able to test a unit in isolation saves clock cycles and, therefore,
time.
The faster turn around may become an encouragement to do more experiments, craft
better tests, and be more productive.

This library is an attempt to provide more unit testing flexibility and
capability that is absent from the default unit test execution.




## Features

The library provides the ability to run specific tests during development,
maintenance, and enhancement efforts.
It also allows the programmer to opt-out and revert to the default unit test
execution if necessary.

* __Unit Test Block Execution__

  The programmer can choose to execute only a specific unit test block or a
  group of them that is of immediate concern.
  This helps the programmer to focus on the 'unit' without being bothered by
  other unit tests that may, at this point, fail.

* __Module Unit Test Execution__

  The programmer can also choose to execute all unit tests in a single module,
  also without being flooded with failed tests from other modules.

* __Module Exclusion__

  In contrast with the _Module Unit Test Execution_, the library also allows
  modules to be excluded from unit test execution.

  This feature is a consequence of determining which modules do not have unit
  tests.
  Packages that simply declare public imports are candidates for this.

* __Detailed Reporting__

  The library provides a detailed report of the unit test execution.

  * Reports the line number and _name_ of executed unit test blocks;
  * Summary of successful and failed unit test blocks per module;
  * Summary of all successful and failed unit test blocks;
  * List of modules with unit tests;
  * List of modules with unit tests but without `sut` prologue code;
  * List of modules without unit tests;
  * List of excluded modules from unit testing.



## Compiler Compatibility

The following compilers have been tested under GNU/Linux only.
I do not currently have a Microsoft Windows machine to test it.

The oldest compiler used to execute the tests
is version 2.090.0.
It is not known what earlier versions can successfully compile and use the
library.

Latest versions of compilers to successfully compile and use the library are:
* [DMD 2.096.1](http://downloads.dlang.org/releases/2.x/2.096.1)
* [LDC 1.25.1](https://github.com/ldc-developers/ldc/releases/tag/v1.25.1)



## Limitations

* Cannot be used with ``-betterC`.
  The library cannot be used if D source is compiled without `ModuleInfo`.
  That includes source codes being compiled with the `-betterC` flag since the
  flag disables the use of `ModuleInfo`.

* Cannot be used with `@nogc`.

* Cannot be used with `nothrow`.

* Cannot be used with `pure`.



## Usage

In summary, this is how to use the library:

__Basic Usage__

* incorporate the module into your project;
* use a _Wrapper Module_;
* statically import the _Wrapper Module_;
* add _user-defined attributes_ before unit test blocks;
* add unit test block prologue code at the top of unit test blocks;
* pass the unit testing flag (--unittest) and the version identifier `sut`
  to the compiler.

Unit tests without _user-defined attributes_ or unit test block prologue code
will still execute but they will not be reported in the console output since
the library uses the prologue code to collect information for reporting.

__Selective Unit Tests__

* to select unit test blocks to execute, create/edit a _unit test configuration
  file_ and add unit test block entries;
* to select modules to execute, create/edit a _unit test configuration file_
  and add module entries;
* pass the configuration file as command-line argumnt to the test program.



### Incorporating 'sut' Module

To use the module, the compiler must be able to _see_ its source code.
This could be done using the `-I` compiler option for `dmd` or `ldc` and
passing the path to the `sut` source code.

The following shows an example of a project directory.
It shows where the `sut` module may be placed.

~~~
...
`-- project
    |-- ...
    |-- build
    |   `-- sut.conf        // selective unit testing configuraiton file
    |-- extern
    |   |-- sut             // this module
    |   `-- ...             // other external dependencies
    `-- src                 // <<<<< we are here
        |-- main.d
        |-- module_a.d
        |-- module_b.d
        |-- sut_wrapper.d   // sut wrapper module
        `-- ...
~~~

To compile the example project above, the following command may be used.

~~~
$ dmd                   \
    -I=.                \   # Look for imports in project/src
    -I=../extern/sut    \   # Look for imports in project/extern/sut
    -i                  \   # include imported modules in code
    -debug              \
    -unittest           \   # unit test flag
    -version=sut        \   # required version identifier when running unit tests
    -of=project         \
    -run                \
    -c ../build/sut.conf
~~~



### SUT Wrapper Module

The _wrapper module_ conditionally enables or disables the use of the library.
The library is enabled by the use of the version identifier `sut`.
See the _Version Identifier_ section below.

It is possible to use the library without using a _wrapper module_.
But using a _wrapper module_ makes it seemless to revert to the default unit
test execution.

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

When using a wrapper module, calls to `unitTestBlockPrologue` and
`excludeModule` are qualified with the _wrapper module_ name.
This is because the client code imports the _wrapper module_ statically.
See the following _Functions_ section.

~~~d
module sut_wrapper;
...
enum prologue=`mixin (sut_wrapper.unitTestBlockPrologue);`;
enum exclude=`mixin (sut_wrapper.excludeModule);`;
~~~

It is possible not to statically import the _wrapper module_ but doing so may
lead to possible name conflicts.
It is therefore advised to follow the safer path and use `static import`.



### Functions

The `sut` module provides the following functions to be used in a
[`mixin`](https://dlang.org/spec/statement.html#mixin-statement) statement:

* unitTestBlockPrologue
* excludeModule

The client code statically imports the _wrapper module_ as in the following:

~~~d
version (unittest) {
    static import sut_wrapper;
}
~~~



#### unitTestBlockPrologue

The code controls whether to continue execution or return early from the block
along and collects information about the unit test block.
It is therefore necessary that it be in the first line inside the unit test
block.

The code looks for a
[`user-defined attribute`](https://dlang.org/spec/attribute.html#uda)
(UDA) for the unit test block and uses the first UDA string as the _unit test
block name_.
If it cannot find one, it uses the compiler-generated unit test block identifier.
It is advised to use a UDA string to allow better identification of unit test
blocks when using _selective unit test block_ execution.
See the _Unit Test Configuration File_ section below on how to use this feature.

~~~d
@("some name")
unittest {
    mixin (sut_wrapper.prologue);
    ...
}
~~~



#### excludeModule

Adds the module name to an exclusion list.
The unit test runner skips execution of the module unit tests if it finds the
module name in the exclusion list.

It is intended to be used at the top of the module possibly before or after import declarations.

~~~d
version (unittest) {
    static import sut_wrapper;
    mixin (sut_wrapper.exclude);
}
~~~



### Version Identifier

To use the library, the version identifier `sut` must be passed to the compiler.
It is used by the `sut` module for conditional compilation and static checks.

~~~
$ dmd -version=sut
$ ldc --d-version=sut
$ ldmd2 -version=sut
~~~



### Unit Test Configuration File

The _unit test configuration file_ contains all unit test block and module
names to be executed.
They are then placed in an execution list.
When the unit test runner determines that a module or a unit test block is
found in the execution list, then they are executed.
Otherwise, they are skipped.

The _unit test configuration file_ must follows these formatting rules:

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

One or more _unit test configuration files_ can be passed to the test program
via command-line argument.

~~~
$ ../compile test.d -c<file1> -c <file2> --config=<file3> --config <file4>
~~~



#### Unit Test Block Names

Unit test block names are checked in the execution list and executed when it
is found.

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



#### Module Names

The same with the _Unit Test Block Names_, modules are executed conditionally.
The all unit tests of a module is executed when the module name is present in
the execution list.



## Basic Usage Example

Let us begin with the _with_wrapper_ test program to demonstrate the basic use
of the library without unit test filtering and show the console output.
This test program has four D source files:

* `test.d` - main module with a couple of unit tests.
* `mul.d` - a module with a unit test to show per module and summary reporting
            output for such modules.
* `excluded.d` - a module with a unit test to show how to exclude a module from
                 unit test execution.
* `no_unittest.d` - a module without a unit test to show summary reporting
                    output for such modules.
* `no_prologue.d` - a module with a unit test but does not use the prologue code.
* `sut.conf` - unit test configuration file for this test program is empty
               which means there will be no filtering of unit tests.

The following are the contents of each file starting with the main module.

* __test.d__

  ~~~d
  module test.with_wrapper.test;

  import test.with_wrapper.mul;
  import test.with_wrapper.no_prologue;
  import test.with_wrapper.no_unittest;
  import test.with_wrapper.excluded;
  version (unittest) {
      static import test.with_wrapper.sut_wrapper;        // import
  }

  int add (const int arg, const int n) {
      return arg + n;
  }
  @("add")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // prologue code
      assert (add(10, 1) == 11);
  }

  int sub (const int arg, const int n) {
      return arg - n;
  }
  @("sub")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // prologue code
      assert (sub(10, 1) == 9);
  }
  ~~~

* __mul.d__

  ~~~d
  module test.with_wrapper.mul;

  version (unittest) {
      static import test.with_wrapper.sut_wrapper;        // import
  }

  size_t mul (const int arg, const int n) {
      return arg * n;
  }
  @("mul")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // prologue code
      assert (mul(10, 2) == 20);
  }
  ~~~

* __excluded.d__

  ~~~d
  module test.with_wrapper.excluded;

  version (unittest) {
      static import test.with_wrapper.sut_wrapper;        // import
      mixin (test.with_wrapper.sut_wrapper.exclude);      // exclude module
  }

  int div (const int arg, const int n) {
      return arg / n;
  }
  @("div")
  unittest {
      mixin (test.with_wrapper.sut_wrapper.prologue);     // prologue code
      assert (div(10, 1) == 10);                          // never executed
  }
  ~~~

* __no_unittest.d__

  ~~~d
  /**
   * Module without unit test.
   */
  module test.with_wrapper.no_unittest;
  ~~~

* __no_prologue.d__

  ~~~d
  module test.with_wrapper.no_prologue;

  size_t square (const uint arg) {
      return arg * arg;
  }
  unittest {
      assert (square(10) == 100);
  }
  ~~~

Compile the source files using either of the commands below.

~~~
$ ../compile.sh test.d
$ ../compile.sh --ldc test.d
~~~

It will automatically run the unit tests.

~~~
$ ../compile.sh test.d
Using selective unit testing module.
[unittest] Start    2021-Apr-23 18:00:07.226723
[unittest]          Digital Mars D version 2.96
[unittest]          D specification version 2
[unittest] Mode:    All
[unittest] Module:  test.with_wrapper.test   15 add
[unittest]          test.with_wrapper.test   24 sub
[unittest]          test.with_wrapper.test - 2 passed, 0 failed, 2 found - 0.000s
[unittest] Module:  test.with_wrapper.mul   11 mul
[unittest]          test.with_wrapper.mul - 1 passed, 0 failed, 1 found - 0.000s
[unittest]          ========================================
[unittest] Summary: 3 passed, 0 failed, 3 found
[unittest]          3 module(s) with unit test
[unittest]          1 module(s) without unit test
[unittest]          1 module(s) excluded
[unittest] List:    Module(s) with unit test (3)
[unittest]          Module(s) without prologue code have asterisk (*)
[unittest]              test.with_wrapper.mul
[unittest]              test.with_wrapper.no_prologue *
[unittest]              test.with_wrapper.test
[unittest] List:    Module(s) without unit test (1)
[unittest]              test.with_wrapper.no_unittest
[unittest] List:    Module(s) excluded (1)
[unittest]              test.with_wrapper.excluded
[unittest] End      2021-Apr-23 18:00:07.2269942
~~~



## Selective Unit Test Block Execution Example

This example will be using the same _with_wrapper_ test program above.

Choose one of the unit test blocks names you wanted to execute.
Edit the _unit test configuration file_ and add an entry.

* `utb:add`
* `utb:sub`
* `utb:mul`

The _unit test configuration file_ should look something like:

~~~
utb:add
~~~

Compile the source files using one of the commands below.

~~~
$ ../compile.sh test.d -- -csut.conf
$ ../compile.sh test.d -- -c sut.conf
$ ../compile.sh test.d -- --config=sut.conf
$ ../compile.sh test.d -- --config sut.conf
~~~

Choosing `utb:add` shows the following output:

~~~
Using selective unit testing module.
[unittest] Start    2021-Apr-23 18:02:56.9533576
[unittest]          Digital Mars D version 2.96
[unittest]          D specification version 2
[unittest] Mode:    Selection
[unittest]            block:  add
[unittest] Module:  test.with_wrapper.test   15 add
[unittest]          test.with_wrapper.test - 1 passed, 0 failed, 2 found - 0.000s
[unittest]          ========================================
[unittest] Summary: 1 passed, 0 failed, 3 found
[unittest]          3 module(s) with unit test
[unittest]          1 module(s) without unit test
[unittest]          1 module(s) excluded
[unittest] List:    Module(s) with unit test (3)
[unittest]          Module(s) without prologue code have asterisk (*)
[unittest]              test.with_wrapper.mul
[unittest]              test.with_wrapper.no_prologue *
[unittest]              test.with_wrapper.test
[unittest] List:    Module(s) without unit test (1)
[unittest]              test.with_wrapper.no_unittest
[unittest] List:    Module(s) excluded (1)
[unittest]              test.with_wrapper.excluded
[unittest] End      2021-Apr-23 18:02:56.9535918
~~~



## Selective Module Execution Example

This example will be using the same _with_wrapper_ test program above.

Choose one of the modules you wanted to execute.
Edit the _unit test configuration file_ and add an entry.

* `utm:test.with_wrapper.mul`
* `utm:test.with_wrapper.test`

The _unit test configuration file_ should look something like:

~~~
utm:test.with_wrapper.mul
~~~

Compile the source files using one of the commands below.

~~~
$ ../compile.sh test.d -- -csut.conf
$ ../compile.sh test.d -- -c sut.conf
$ ../compile.sh test.d -- --config=sut.conf
$ ../compile.sh test.d -- --config sut.conf
~~~

Choosing `utm:test.with_wrapper.mul` shows the following output:

~~~
Using selective unit testing module.
[unittest] Start    2021-Apr-23 18:06:47.0770861
[unittest]          Digital Mars D version 2.96
[unittest]          D specification version 2
[unittest] Mode:    Selection
[unittest]            module: test.with_wrapper.mul
[unittest] Module:  test.with_wrapper.mul   11 mul
[unittest]          test.with_wrapper.mul - 1 passed, 0 failed, 1 found - 0.000s
[unittest]          ========================================
[unittest] Summary: 1 passed, 0 failed, 3 found
[unittest]          3 module(s) with unit test
[unittest]          1 module(s) without unit test
[unittest]          1 module(s) excluded
[unittest] List:    Module(s) with unit test (3)
[unittest]          Module(s) without prologue code have asterisk (*)
[unittest]              test.with_wrapper.mul
[unittest]              test.with_wrapper.no_prologue *
[unittest]              test.with_wrapper.test
[unittest] List:    Module(s) without unit test (1)
[unittest]              test.with_wrapper.no_unittest
[unittest] List:    Module(s) excluded (1)
[unittest]              test.with_wrapper.excluded
[unittest] End      2021-Apr-23 18:06:47.0774876
~~~



## Test Programs

The repository contains different test programs that are good enough to
demonstrate how to use this module.
The directory structure below shows where they can be found.
You can download or clone the repository and run the tests with the command
`../compile.sh test.d [-c<file>...]`.

~~~
...
`-- src
    |-- sut                     // this module
    |   ...
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
