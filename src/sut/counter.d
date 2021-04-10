module sut.counter;

import sut.prologue;




/**
 * Unit test counter for each module.
 *
 * Updated from the unit test block and the custom unit test runner.
 */
public
static
UnitTestCounter moduleCounter;



/** Alias */
alias UnitTestCounter = Counter;



/**
 * Module unit test block counters.
 */
struct Counter
{
    /** Number of Unit test blocks that were successfully executed. */
    size_t passing = 0;

    /** Number of Unit test blocks that threw an assertion. */
    size_t failing = 0;

    /** Number of Unit test blocks that were skipped. */
    size_t skipped = 0;

    /** Number of Unit test blocks that were found. */
    size_t total = 0;



    invariant
    {
        assert (passing <= total);
        assert (failing <= total);
        assert (skipped <= total);
        // Because we manually set the total first before setting
        // other fields.
        assert (total >= passing + failing + skipped);
    }



    /** Set to initial values. */
    void
    reset ()
    {
        passing = 0;
        failing = 0;
        skipped = 0;
        total = 0;
    }


    void
    addPassing ()
    {
        passing++;
    }

    void
    addFailing ()
    {
        failing++;
    }

    void
    addSkipped ()
    {
        skipped++;
    }

    void
    addTotal ()
    {
        total++;
    }


    /**
     * Revert previous call to `addPassing` and do an `addFailing` call.
     */
    void
    revertPassing ()
    {
        import std.exception: enforce;
        enforce(passing > 0, "Cannot decrement zero (Count.passing).");
        passing--;
        addFailing();
    }

    void
    add (const Counter arg)
    {
        passing = arg.passing;
        failing = arg.failing;
        skipped = arg.skipped;
        total = arg.total;
    }


    bool
    isAllPassing () const
    {
        return passing > 0 && failing == 0;
    }

    bool
    isSomePassing () const
    {
        return passing > 0 && failing > 0;
    }

    bool
    isNoneFailing () const
    {
        return failing == 0 && total > 0;
    }

    /**
     * Determine whether `skip` is greater than zero.
     *
     * Returns: `true` when `skip` is less than `found` but not zero.
     */
    bool
    isSomeExecuted () const
    {
        const executed = passing + failing;
        return total > 0 && executed > 0 && executed < total;
    }
    @("isSomeExecuted")
    unittest {
        //mixin (unitTestBlockPrologue());
        assert (!Counter().isSomeExecuted());
        assert (Counter().setPass(5).setFail(2).setTotal(7).isSomeExecuted());
        assert (Counter().setPass(5).setSkip(2).setTotal(7).isSomeExecuted());
        assert (Counter().setFail(2).setSkip(5).setTotal(7).isSomeExecuted());
    }



    /**
     * Determine whether `skip` equals `found` but not zero.
     *
     * Returns: `true` when `skip` equals `found` but not zero.
     */
    bool
    isAllSkipped () const
    {
        return total > 0 && skipped == total;
    }
    @("isAllSkipped")
    unittest {
        //mixin (unitTestBlockPrologue());
        assert (!Counter().isAllSkipped());
        assert (!Counter().setTotal(7).isAllSkipped());
        assert (!Counter().setSkip(1).setTotal(7).isAllSkipped());
        assert (Counter().setSkip(7).setTotal(7).isAllSkipped());
    }



    /**
     * Determine whether `skip` is greater than zero.
     *
     * Returns: `true` when `skip` is less than `found` but not zero.
     */
    bool
    isSomeSkipped () const
    {
        return total > 0 && skipped > 0 && skipped < total;
    }
    @("isSomeSkipped")
    unittest {
        //mixin (unitTestBlockPrologue());
        assert (!Counter().isSomeSkipped());
        assert (!Counter().setTotal(7).isSomeSkipped());
        assert (Counter().setSkip(1).setTotal(7).isSomeSkipped());
        assert (Counter().setSkip(7).setTotal(7).isSomeSkipped());
    }

    bool
    isNoneSkipped () const
    {
        return skipped == 0 && total > 0;
    }



    /** Unit test helper functions */
    version (unittest) {

        ref Counter
        setPass (const size_t arg)
        return @safe pure nothrow @nogc do
        {
            passing = arg;
            return this;
        }

        ref Counter
        setFail (const size_t arg)
        return @safe pure nothrow @nogc do
        {
            failing = arg;
            return this;
        }

        ref Counter
        setSkip (const size_t arg)
        return @safe pure nothrow @nogc do
        {
            skipped = arg;
            return this;
        }

        ref Counter
        setTotal (const size_t arg)
        return @safe pure nothrow @nogc do
        {
            total = arg;
            return this;
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
                && skipped == 0
                && total == 0;
        }
    }
}
@("UnitTestCounter")
unittest {
    //mixin (unitTestBlockPrologue());
    assert (Counter().isUnset());
    assert (!Counter().setPass(1).isUnset());
}
