module sut.execution;

import sut.util:
    beginsWith,
    isFound;

static import sut.wrapper;


/**
 * Holds a collection of modules and unit test blocks to be executed.
 *
 * The contents of the lists are acquired from the unit test configuration file
 * imported into the program using import expression.
 */
static
ExecutionList executionList;



private:



struct ExecutionList
{
    /**
     * Names of unit tests to be executed.
     */
    string[] unittests;

    /**
     * Names of modules to be executed.
     */
    string[] modules;



    /**
     * Determine whether the string argument matches any entry in the unit test
     * execution list.
     *
     * Returns: `true` if a match is found.
     */
    bool
    isUnitTestFound (const string arg) const
    {
        return isFound(unittests, arg);
    }



    /**
     * Determine whether the string argument begins with any entry in the module
     * execution list.
     *
     * Returns: `true` if a match is found.
     */
    bool
    isModuleFound (const string arg) const
    {
        return beginsWith(modules, arg);
    }



    /**
     * Determine whether the unittest and module lists are empty.
     */
    bool
    isEmpty () const
    {
        return unittests.length == 0 && modules.length == 0;
    }
}
@("ExecutionList: empty")
unittest {
    mixin (sut.wrapper.prologue);
    ExecutionList exec;
    assert (exec.isEmpty());
    assert (exec.unittests == (string[]).init);
    assert (exec.modules == (string[]).init);
}
@("ExecutionList: unittests")
unittest {
    mixin (sut.wrapper.prologue);
    ExecutionList exec;
    exec.unittests = ["one", "three", "two"];
    exec.modules = (string[]).init;
    assert (!exec.isEmpty());
    assert (exec.isUnitTestFound("unit test: two"));
    assert (!exec.isModuleFound("two"));
}
@("ExecutionList: modules")
unittest {
    mixin (sut.wrapper.prologue);
    ExecutionList exec;
    exec.unittests = (string[]).init;
    exec.modules = ["one", "three", "two"];
    assert (!exec.isEmpty());
    assert (!exec.isUnitTestFound("two"));
    assert (!exec.isModuleFound("module two"));
    assert (exec.isModuleFound("two"));
}
