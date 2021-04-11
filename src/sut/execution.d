module sut.execution;

import sut.config:
    getModules,
    getUnitTestBlocks;
import sut.util:
    beginsWith,
    isFound,
    toArray;


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
    static
    string[] unittests;

    /**
     * Names of modules to be executed.
     */
    static
    string[] modules;



    /**
     * Determine whether the string argument matches any entry in the unit test
     * execution list.
     *
     * Returns: `true` if a match is found.
     */
    bool
    isUnitTestFound (const string arg)
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
    isModuleFound (const string arg)
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



    /**
     * Get the module and unittest block execution list.
     * Populate the unit test block and module execution lists.
     *
     */
    void
    set (const string arg = string.init)
    {
        const arr = arg.toArray();
        unittests = arr.getUnitTestBlocks();
        modules = arr.getModules();
    }
}
@("Execution: empty")
unittest {
    //mixin (unitTestBlockPrologue());
    ExecutionList exec;
    exec.set();
    assert (exec.isEmpty());
    assert (exec.unittests == (string[]).init);
    assert (exec.modules == (string[]).init);
}
@("Execution: spaces and new lines only")
unittest {
    //mixin (unitTestBlockPrologue());
    enum INPUT=" \n \n \n";
    ExecutionList exec;
    exec.set(INPUT);
    assert (exec.isEmpty());
    assert (exec.unittests == (string[]).init);
    assert (exec.modules == (string[]).init);
}
@("Execution: unittests")
unittest {
    //mixin (unitTestBlockPrologue());
    enum INPUT="utb:one\nutb:two\n\nutb:three";
    ExecutionList exec;
    exec.set(INPUT);
    assert (!exec.isEmpty());
    assert (exec.unittests == ["one", "three", "two"]);
    assert (exec.modules == (string[]).init);
    assert (exec.isUnitTestFound("unit test: two"));
    assert (!exec.isModuleFound("two"));
}
@("Execution: modules")
unittest {
    //mixin (unitTestBlockPrologue());
    enum INPUT="utm:one\nutm:two\n\nutm:three";
    ExecutionList exec;
    exec.set(INPUT);
    assert (!exec.isEmpty());
    assert (exec.unittests == (string[]).init);
    assert (exec.modules == ["one", "three", "two"]);
    assert (!exec.isUnitTestFound("two"));
    assert (!exec.isModuleFound("module two"));
    assert (exec.isModuleFound("two"));
}
