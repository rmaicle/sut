# Selective Unit Testing

A D programming language custom unit test runner that allows selective unit
test execution.



## Rationale

Currently, the execution of unit tests in the D runtime module is an all or
nothing approach.
Selectively executing unit tests is not supported.

Development, maintenance, and enhancement of fine-grained details and components
require testing to be performed at that level in isolation.
In the context of testing an enhancement involving a single function, running
the default unit test runner will:

  * run unit tests for the modified function
  * run unit tests in the same module
  * run unit tests of other referenced user-defined modules

In this bottom-up scenario, the immediate concern is the first operation.
The other two operations, which incur extra runtime, can be performed after.

Using this module provides the capability to selectively execute unit tests
in a bottom-up approach although it would require inserting extra code in
module scope and unit test blocks.



## Necessary Extra Code

To use, it is necessary to insert some code.
First, the module must be statically imported, define user-defined attribute
(UDA) for the unit test block, and insert code before the execution of the rest
of the unit test block.
This last statement is neessary since it controls whether to continue the
execution of the rest of the block or abort (early return).

~~~d
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
~~~



## Unit Test Configuration File

The unit test configuration file, _unittest.conf_, contains all unit test block
and module names that will be executed.

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

The directory where the unit test configuration file is in needs to be specified
to the compiler using the `-J` option.
The option tells the compiler the directories where to find import expressions.

~~~
dmd -unittest -J=<directory> ...
ldc --unittest -J=<directory> ...
~~~



## Change Log

The detailed log of changes can be seen on [CHANGELOG.md](CHANGELOG.md) file.



## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
