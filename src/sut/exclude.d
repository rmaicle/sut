module sut.exclude;

import sut.util:
    dedup,
    remove;

static import sut.wrapper;
debug import std.stdio;



static this () {
    version (sut_internal_unittest) {
        exclusionList.add("sut");
        exclusionList.add("sut.output");
        exclusionList.add("sut.runtime");
        exclusionList.add("sut.wrapper");
    }
}

/**
 * Holds the list of modules to be excluded from exection.
 *
 * The contents of the list is acquired using `excludeModule`.
 */
static
ExclusionList exclusionList;



/**
 * Generate the code to be passed to a mixin expression in the calling module.
 *
 * The generated code explicitly excludes the module from execution.
 */
string
excludeModule ()
{
    import std.format: format;
    return format!`
    static this () {
        static import sut;
        import std.traits: moduleName;
        template xyz_123_abc (T) { }
        sut.exclusionList.add(moduleName!xyz_123_abc);
    }`();
}



private:



/**
 * Excluded modules.
 *
 * Module names found in this list are reported as excluded modules and not
 * as modules without unit tests.
 */
struct ExclusionList
{
    /**
     * List containing module names.
     */
    string[] list;



    /**
     * Append an item in the list.
     */
    void
    add (const string arg)
    {
        if (!isFound(arg)) {
            list ~= arg;
        }
    }
    @("ExclusionList.add")
    unittest {
        mixin (sut.wrapper.prologue);
        ExclusionList exclusion;
        exclusion.add("one");
        exclusion.add("one");
        exclusion.add("two");
        exclusion.add("two");
        assert (exclusion.list.length == 2);
        assert (exclusion.list == ["one", "two"]);
    }



    /**
     * Determine whether the module name argument is found in the list.
     *
     * Returns: `true` if the module name is found in the list.
     */
    bool
    isFound (const string arg)
    {
        import std.algorithm: canFind;
        return list.canFind(arg);
    }
    @("ExclusionList.isFound")
    unittest {
        mixin (sut.wrapper.prologue);
        ExclusionList exclusion;
        exclusion.list = ["one", "two"];
        assert (exclusion.isFound("one"));
        assert (exclusion.isFound("two"));
    }



    /**
     * Filter the list by removing duplicates and removing items found
     * in the array string argument.
     *
     * Returns: `string[]` as the filtered list.
     */
    string[]
    filter (const string[] arg)
    {
        return list.dedup.remove(arg);
    }
    @("ExclusionList.filter")
    unittest {
        mixin (sut.wrapper.prologue);
        ExclusionList exclusion;
        exclusion.list = ["one", "two", "one", "two"];
        assert (exclusion.filter(["one"]) == ["two"]);
        exclusion.list = ["one", "two", "one", "two"];
        assert (exclusion.filter(["two"]) == ["one"]);
    }
}
