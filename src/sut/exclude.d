module sut.exclude;

import sut.util:
    dedup,
    remove;

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
 * Client-facing mixin code for adding the module to the exclusion list.
 */
string
excludeModule (size_t LN = __LINE__)()
{
    import std.format: format;
    enum ModuleName = format!("module_name_L%d__")(LN);
    return `static this () {
    static import sut;
    import std.traits: moduleName;
    struct dummyXYZ { }` ~
    format!("\nenum %s = moduleName!dummyXYZ;")(ModuleName) ~
    format!("\nsut.exclusionList.add(moduleName!%s);")(ModuleName) ~
    "}";
}



private:



/**
 * Excluded modules.
 *
 * Module names found in this list are not reported as having no unit tests.
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
    @("add")
    unittest {
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
    @("isFound")
    unittest {
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
}
