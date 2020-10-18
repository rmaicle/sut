# Custom Unit Test Execution

Unit test helper that allows selective unit test execution of modules and
unit test blocks whose "names" are found in the file, `unittest.conf`.



## Rationale

Currently, the execution of unit tests in the D runtime module is an all or
nothing approach. Selectively executing unit tests is not supported.

Development, maintenance, and enhancement of fine-grained details and
components require testing to be performed at that level in isolation.
In the context of testing an enhancement involving a single function,
running all unit tests of the module it belongs to and all imported user-
created modules is kind of an overkill. Also, running other unit tests in
those modules will incur extra time that is not of concern at that point.

This module aims to provide the capability to selectively execute unit tests
although it requires extra code to be inserted in module scope and unit test
test blocks.



## Necessary Extra Code

To use, it is necessary to insert some code. First, the module must be
statically imported, define user-defined attribute (UDA) for the unit test
block, and insert code before the execution of the rest of the unit test
block. This last statement is neessary since it controls whether to continue
the execution of the rest of the block or abort (early return).

~~~~~~~~~~
version (unittest) static import sut;           // 1 - import module
bool isEmpty (const string arg) {
  return arg.length == 0;
}
@("isEmpty")                                    // 2 - UDA
unittest {
  mixin (sut.unitTestBlockPrologue());          // 3 - insert prologue
  assert (isEmpty(""));
  assert (!isEmpty("hello"));
}
~~~~~~~~~~



## Unit Test Config File

The unit test config file, 'unittest.conf' contains the unit test block names
and module names that will be executed.
Each unit test block name and module name is declared on one line. Unit test
block names are prefixed with `utb:` and module names with `mod:`.

~~~~~~~~~~
utb:<unit test block name>
utm:<module name>
~~~~~~~~~~

The directory where the unit test config file is in needs to be specified to
the compiler using the `-J` option. The option tells the compiler the
directories where to find import expressions.

~~~~~~~~~~
dmd -J=<directory> ...
ldc -J=<directory>
~~~~~~~~~~



# Change Log

The detailed log of changes can be seen on [CHANGELOG.md](CHANGELOG.md)
file.
