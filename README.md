# Selective Unit Testing

A D programming language custom unit test runner that allows selective unit
test execution.



## Rationale

Currently, the execution of unit tests in the D runtime module is an all or
nothing approach.
Selectively executing unit tests is not supported.

Development, maintenance, and enhancement of fine-grained details and
components require testing to be performed at that level in isolation.
In the context of testing an enhancement involving a single function,
running the default unit test runner will:

  * run unit tests for the modified function
  * run unit tests in the same module
  * run unit tests of other referenced user-defined modules

In this bottom-up scenario, the immediate concern is the first operation.
The other two operations, which incur extra runtime, can be performed after.

Using this module provides the capability to selectively execute unit tests
in a bottom-up approach although it would require inserting extra code in
module scope and unit test blocks.



## Compatibility

This module is not compatible with D source code that does not use `ModuleInfo`
and source codes being compiled with the `-betterC` flag.



## Necessary Extra Code

Create a module that encapsulates some compile-time logic to avoid bloating
the using modules with duplicate codes.

~~~d
module internal.sut;

version (unittest):

// Compile-time test whether the `sut` module can be found and imported
static if (__traits(compiles, { import sut; })) {
    public static import sut;
}

enum prologue=`
    // Compile-time test whether the `sut` module can be found and imported
    static if (__traits(compiles, { import sut; })) {
        // Note the fully qualified call
        mixin (internal.sut.unitTestBlockPrologue());
    }`;
~~~

A note on the mixin line, `mixin (internal.sut.unitTestBlockPrologue())`.
The name of the encapsulating module must be used here.

The modules that uses the selective unit test module can be written without
the compile-time checks.

~~~d
version (unittest) static import internal.sut;  // 1 - import module
bool isEmpty (const string arg) {
  return arg.length == 0;
}
@("isEmpty")                                    // 2 - UDA
unittest {
  mixin (internal.sut.prologue);                // 3 - insert prologue
  assert (isEmpty(""));
  assert (!isEmpty("hello"));
}
~~~



## Version Identifiers

To use the module, the version identifier `sut` must be passed to the
compiler.

The version identifier, `exclude_sut`, must also be passed to the compiler
to exclude those unit tests inside the module itself.

~~~
dmd -version=sut -version=exclude_sut ...
ldc --d-version=sut --d-version=exclude_sut ...
~~~



## Unit Test Configuration File

The unit test configuration file, _unittest.conf_, contains all unit test
block and module names that will be executed.

Formatting guide:

* one name per line
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



## Compiler Option

The configuration file directory must be specified to the compiler using the
`-J` option.
This commandline option tells the compiler where to look for
string imports.

~~~
dmd -unittest -J=<directory> ...
ldc --unittest -J=<directory> ...
~~~



## Change Log

The detailed log of changes can be seen on [CHANGELOG.md](CHANGELOG.md) file.



## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
