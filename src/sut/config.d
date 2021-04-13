module sut.config;

import sut.prologue;
import sut.util:
    toArray,
    unprefix;

debug import std.stdio;



/**
 * Static `Config` instance.
 */
static
Config config;



private:



enum BLOCK_PREFIX = "utb";
enum MODULE_PREFIX = "utm";
enum SEPARATOR = ":";



struct Config
{
    string[] unittests;
    string[] modules;
    string[] unknown;



    /**
     * Read the contents of the file specified by the string argument.
     */
    void
    read (const string arg)
    {
        import std.file: readText;
        import std.algorithm: startsWith;
        auto content = arg.readText().toArray();
        foreach (item; content) {
            if (item.startsWith(BLOCK_PREFIX)) {
                unittests ~= item.unprefix(BLOCK_PREFIX, SEPARATOR.length);
            } else if (item.startsWith(MODULE_PREFIX)) {
                modules ~= item.unprefix(MODULE_PREFIX, SEPARATOR.length);
            } else {
                unknown ~= item;
                writeln ("Unknown configuration item: ", item);
            }
        }
    }



    /**
     * Initialize fields to defaults.
     */
    void
    reset ()
    {
        unittests = (string[]).init;
        modules = (string[]).init;
        unknown = (string[]).init;
    }
}
