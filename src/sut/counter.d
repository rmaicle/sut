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
__gshared
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
    addModulesWithPrologue (const string arg)
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
    reset ()
    {
        passing = 0;
        failing = 0;
        total = 0;
    }


    /**
     * Increment passing field.
     */
    void
    addPassing () { passing++; }



    /**
     * Incrememnt failing field.
     */
    nothrow
    void
    addFailing () { failing++; }



    /**
     * Increment total field.
     */
    void addTotal () { total++; }



    /**
     * Revert previous call to `addPassing` and do an `addFailing` call.
     */
    nothrow
    void
    revertPassing ()
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
    isUnset () const
    {
        return passing == 0
            && failing == 0
            && total == 0;
    }
    @("UnitTestStats.isUnset")
    unittest {
        mixin (sut.wrapper.prologue);
        alias Stats = UnitTestStats;
        assert (Stats().isUnset());
        assert (!Stats(1).isUnset());
        assert (!Stats(1).setPassing(1).isUnset());
    }



    /**
     * Determine whether passing field is equal to total field.
     *
     * Returns: `true` if passing field is equal to total field.
     */
    bool
    isAllPassing () const
    {
        return passing == total;
    }
    @("UnitTestStats.isAllPassing")
    unittest {
        mixin (sut.wrapper.prologue);
        alias Stats = UnitTestStats;
        assert (Stats().isUnset());
        assert (Stats().isAllPassing());
        assert (Stats(7).setPassing(7).isAllPassing());
        assert (!Stats(7).setPassing(5).isAllPassing());
        assert (!Stats(7).setFailing(2).isAllPassing());
    }



    /**
     * Determine whether failing field is zero.
     *
     * Returns: `true` if failing field is zero.
     */
    bool
    isNoneFailing () const
    {
        return failing == 0;
    }
    @("UnitTestStats.isNoneFailing")
    unittest {
        mixin (sut.wrapper.prologue);
        alias Stats = UnitTestStats;
        assert (Stats().isNoneFailing());
        assert (Stats(7).setPassing(7).isNoneFailing());
        assert (Stats(7).setPassing(5).isNoneFailing());
        assert (!Stats(7).setFailing(2).isNoneFailing());
    }



    /**
     * Determine whether there executed unit tests.
     *
     * Returns: `true` if passing or failing field is greater than zero.
     */
    bool
    isSomeExecuted () const
    {
        return total > 0 && (passing > 0 || failing > 0);
    }
    @("UnitTestStats.isSomeExecuted")
    unittest {
        mixin (sut.wrapper.prologue);
        alias Stats = UnitTestStats;
        assert (!Stats().isSomeExecuted());
        assert (Stats(7).setPassing(7).isSomeExecuted());
        assert (Stats(7).setPassing(5).isSomeExecuted());
        assert (Stats(7).setFailing(2).isSomeExecuted());
    }



    /**
     * Helper functions for unit testing.
     */
    version (unittest) {

        /**
         * Set total on initialization.
         */
        this (size_t arg)
        {
            total = arg;
        }

        ref UnitTestStats
        setPassing (const size_t arg)
        return @safe pure nothrow @nogc do
        {
            passing = arg;
            return this;
        }

        ref UnitTestStats
        setFailing (const size_t arg)
        return @safe pure nothrow @nogc do
        {
            failing = arg;
            return this;
        }

        ref UnitTestStats
        setTotal (const size_t arg)
        return @safe pure nothrow @nogc do
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
    enter ()
    {
        flag = true;
    }

    void
    leave ()
    {
        flag = false;
    }

    nothrow
    bool
    isIn () const
    {
        return flag;
    }
}
