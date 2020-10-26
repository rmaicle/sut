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
    /** Unit test blocks that were successfully executed. */
    size_t pass = 0;

    /** Unit test blocks that were skipped. */
    size_t skip = 0;

    /** Unit test blocks that were skipped. */
    size_t found = 0;



    /** Set to initial values. */
    void
    reset ()
    {
        pass = 0;
        skip = 0;
        found = 0;
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
            return pass == 0 && skip == 0 && found == 0;
        }
    }
}
unittest {
    mixin (unitTestBlockPrologue());
    UnitTestCounter utc;

    assert (utc.isUnset());
    utc = UnitTestCounter(10, 20, 30);
    assert (!utc.isUnset());
    utc.reset();
    assert (utc.isUnset());
}



/**
 * Determine whether a module have unit test blocks and they are all skipped.
 *
 * Returns: `true` when `UnitTestCounter.found` is greater than zero and that
 *          `UnitTestCounter.skipped` equals to `UnitTestCounter.found`.
 */
bool
isModuleSkipped (const UnitTestCounter arg)
{
    return arg.found > 0 && arg.skip == arg.found;
}
unittest {
    mixin (unitTestBlockPrologue());
    UnitTestCounter utc;

    assert (!utc.isModuleSkipped());
    utc = UnitTestCounter(2, 3, 5);
    assert (!utc.isModuleSkipped());
    utc = UnitTestCounter(0, 5, 5);
    assert (utc.isModuleSkipped());
}



/**
 * Determine whether a module have skipped at least one unit test block.
 *
 * Returns: `true` when at least there is one unit test block that was skipped.
 */
bool
doesModuleHaveSkip (const UnitTestCounter arg)
{
    return arg.found > 0 && arg.skip > 1;
}
