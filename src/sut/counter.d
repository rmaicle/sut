module sut.counter;

import sut.prologue;

static import sut.wrapper;
debug import std.stdio;



/**
 * Unit test counter for each module.
 *
 * Updated from the unit test block and the custom unit test runner.
 */
public
static
UnitTestCounter unitTestCounter;



/**
 * Unit test counter.
 */
struct UnitTestCounter
{
    /**
     * Unit test counter for the current module.
     */
    UnitTestStats current;

    /**
     * Unit test counter for all modules.
     */
    UnitTestStats all;

    // These two arrays are filled from the custom unit test runner.

    /**
     * Modules with unit tests.
     */
    string[] modulesWith;

    /**
     * Modules without unit tests.
     */
    string[] modulesWithout;

    /**
     * Modules with unit test prologue code.
     * Compared with `modulesWith` (modules with unit tests)
     */
    string[] modulesWithPrologue;

    /**
     * Flag whether execution is inside a unit test block with prologue code.
     */
    UnitTestBlock unitTestBlock;



    /**
     * Add values to total.
     */
    void
    accumulate ()
    {
        all.passing += current.passing;
        all.failing += current.failing;
        all.total += current.total;
        current.reset();
    }
    @("accumulate")
    unittest {
        mixin (sut.wrapper.prologue);
        auto counter = UnitTestCounter();
        counter.current.setTotal(1).setPassing(1);
        counter.accumulate();
        assert (counter.all == UnitTestStats(1).setPassing(1));

        counter.current.setTotal(1).setFailing(1);
        counter.accumulate();
        assert (counter.all == UnitTestStats(2).setPassing(1).setFailing(1));
    }



    void
    addModulesWithPrologue (const string arg) @safe
    {
        modulesWithPrologue ~= arg;
    }

}



private:



/**
 * Unit test execution statistics.
 */
struct UnitTestStats
{
    /** Number of init test blocks that were successfully executed. */
    size_t passing = 0;

    /** Number of unit test blocks that threw an assertion. */
    size_t failing = 0;

    /** Number of unit test blocks that were found. */
    size_t total = 0;



    invariant {
        assert (passing <= total);
        assert (failing <= total);
        // Because we manually set the total first before setting
        // other fields.
        assert (total >= passing + failing);
    }



    /** Set to initial values. */
    void
    reset () nothrow @safe
    {
        passing = 0;
        failing = 0;
        total = 0;
    }


    /**
     * Increment passing field.
     */
    void
    addPassing () nothrow @safe
    {
        passing++;
    }



    /**
     * Incrememnt failing field.
     */
    void
    addFailing () nothrow @safe
    {
        failing++;
    }



    /**
     * Increment total field.
     */
    void addTotal () nothrow @safe
    {
        total++;
    }



    /**
     * Revert previous call to `addPassing` and do an `addFailing` call.
     */
    void
    revertPassing () nothrow @safe
    {
        if (passing == 0) {
            throw new Error("Cannot decrement zero.");
        }
        passing--;
        addFailing();
    }
    @("UnitTestStats.revertPassing")
    unittest {
        mixin (sut.wrapper.prologue);
        auto stats = UnitTestStats(1).setPassing(1);
        stats.revertPassing();
        assert (stats == UnitTestStats(1).setFailing(1));
    }



    /**
     * Determine whether all values are equal to initial values.
     *
     * Returns: `true` if all values are equal to initial values.
     */
    bool
    isUnset () const nothrow @safe
    {
        return passing == 0
            && failing == 0
            && total == 0;
    }
    @("UnitTestStats.isUnset")
    unittest {
        mixin (sut.wrapper.prologue);
        assert (UnitTestStats().isUnset());
        assert (!UnitTestStats(1).isUnset());
        assert (!UnitTestStats(1).setPassing(1).isUnset());
    }



    /**
     * Determine whether passing field is equal to total field.
     *
     * Returns: `true` if passing field is equal to total field.
     */
    bool
    isAllPassing () const nothrow @safe
    {
        return passing == total;
    }
    @("UnitTestStats.isAllPassing")
    unittest {
        mixin (sut.wrapper.prologue);
        assert (UnitTestStats().isUnset());
        assert (UnitTestStats().isAllPassing());
        assert (UnitTestStats(7).setPassing(7).isAllPassing());
        assert (!UnitTestStats(7).setPassing(5).isAllPassing());
        assert (!UnitTestStats(7).setFailing(2).isAllPassing());
    }



    /**
     * Determine whether failing field is zero.
     *
     * Returns: `true` if failing field is zero.
     */
    bool
    isNoneFailing () const nothrow @safe
    {
        return failing == 0;
    }
    @("UnitTestStats.isNoneFailing")
    unittest {
        mixin (sut.wrapper.prologue);
        assert (UnitTestStats().isNoneFailing());
        assert (UnitTestStats(7).setPassing(7).isNoneFailing());
        assert (UnitTestStats(7).setPassing(5).isNoneFailing());
        assert (!UnitTestStats(7).setFailing(2).isNoneFailing());
    }



    /**
     * Determine whether there executed unit tests.
     *
     * Returns: `true` if passing or failing field is greater than zero.
     */
    bool
    isSomeExecuted () const nothrow @safe
    {
        return total > 0 && (passing > 0 || failing > 0);
    }
    @("UnitTestStats.isSomeExecuted")
    unittest {
        mixin (sut.wrapper.prologue);
        assert (!UnitTestStats().isSomeExecuted());
        assert (UnitTestStats(7).setPassing(7).isSomeExecuted());
        assert (UnitTestStats(7).setPassing(5).isSomeExecuted());
        assert (UnitTestStats(7).setFailing(2).isSomeExecuted());
    }



    /**
     * Helper functions for unit testing.
     */
    version (unittest) {

        /**
         * Set total on initialization.
         */
        this (const size_t arg)
        {
            total = arg;
        }

        ref UnitTestStats
        setPassing (const size_t arg)
        return pure nothrow @nogc @safe
        {
            passing = arg;
            return this;
        }

        ref UnitTestStats
        setFailing (const size_t arg)
        return pure nothrow @nogc @safe
        {
            failing = arg;
            return this;
        }

        ref UnitTestStats
        setTotal (const size_t arg)
        return pure nothrow @nogc @safe
        {
            total = arg;
            return this;
        }
    }
}




/**
 * Encapsulates a flag to be used whether execution
 * is inside a unit test with prologue code.
 */
struct UnitTestBlock
{
    bool flag = false;

    void
    enter () nothrow @safe
    {
        flag = true;
    }

    void
    leave () nothrow @safe
    {
        flag = false;
    }

    bool
    isIn () const nothrow @safe
    {
        return flag;
    }
}
