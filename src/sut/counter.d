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



/**
 * Module unit test block counters.
 */
struct UnitTestCounter
{
    /** Number of Unit test blocks that were successfully executed. */
    size_t pass = 0;

    /** Number of Unit test blocks that threw an assertion. */
    size_t fail = 0;

    /** Number of Unit test blocks that were skipped. */
    size_t skip = 0;

    /** Number of Unit test blocks that were found. */
    size_t found = 0;



    /** Set to initial values. */
    void
    reset ()
    {
        pass = 0;
        fail = 0;
        skip = 0;
        found = 0;
    }



    /**
     * Determine whether `skip` equals `found` but not zero.
     *
     * Returns: `true` when `skip` equals `found` but not zero.
     */
    bool
    allSkipped ()
    {
        return found > 0 && skip == found;
    }
    @("allSkipped")
    unittest {
        mixin (unitTestBlockPrologue());
        UnitTestCounter utc;

        assert (!utc.allSkipped());
        utc = UnitTestCounter(2, 3, 5);
        assert (!utc.allSkipped());
        utc = UnitTestCounter(0, 5, 5);
        assert (utc.allSkipped());
    }



    /**
     * Determine whether `skip` is less than `found` but not zero.
     *
     * Returns: `true` when at `skip` is less than `found` but not zero.
     */
    bool
    someSkipped ()
    {
        return found > 0 && skip > 0 && skip < found;
    }
    @("someSkipped")
    unittest {
        mixin (unitTestBlockPrologue());
        UnitTestCounter utc;

        assert (!utc.someSkipped());
        utc = UnitTestCounter(0, 5, 5);
        assert (!utc.someSkipped());
        utc = UnitTestCounter(2, 0, 5);
        assert (!utc.someSkipped());
        utc = UnitTestCounter(2, 3, 5);
        assert (utc.someSkipped());
    }



    /** Unit test helper functions */
    version (unittest) {

        /** Constructor. */
        this (
            const size_t p,
            const size_t s,
            const size_t f,
        ) {
            pass = p;
            skip = s;
            found = f;
        }

        /**
         * Determine whether all values are equal to initial values.
         *
         * Returns: `true` if all values are equal to initial values.
         */
        bool
        isUnset () const
        {
            return pass == 0 && fail == 0 && skip == 0 && found == 0;
        }
    }
}
@("UnitTestCounter")
unittest {
    mixin (unitTestBlockPrologue());
    UnitTestCounter utc;

    assert (utc.isUnset());
    utc = UnitTestCounter(10, 20, 30);
    assert (!utc.isUnset());
    utc.reset();
    assert (utc.isUnset());
}
