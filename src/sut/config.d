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



struct FileContent
{
    string filename;
    string[] content;

    this (
        const string arg,
        const string[] args
    ) {
        filename = arg;
        content = args.dup;
    }

    /**
     * Determine whether the container is empty.
     *
     * Returns: `true` if the container is empty.
     */
    bool
    isEmpty () const
    {
        return content.length == 0;
    }
}

alias Unknown = FileContent;



struct Config
{
    string[] unittests;
    string[] modules;
    Unknown[] unknown;



    /**
     * Read the contents of the file specified by the string argument.
     */
    FileContent
    readFile (const string arg)
    {
        import std.file: readText;
        FileContent file;
        file.filename = arg;
        file.content = arg.readText().toArray();
        return file;
    }



    /**
     * Segregate items into corresponding containers.
     */
    void
    filter (const FileContent arg)
    {
        import std.algorithm: startsWith;
        enum BLOCK_PREFIX = "utb";
        enum MODULE_PREFIX = "utm";
        enum SEPARATOR = ":";
        Unknown localUnknown;
        localUnknown.filename = arg.filename;
        foreach (item; arg.content) {
            if (item.startsWith(BLOCK_PREFIX)) {
                unittests ~= item.unprefix(BLOCK_PREFIX, SEPARATOR.length);
            } else if (item.startsWith(MODULE_PREFIX)) {
                modules ~= item.unprefix(MODULE_PREFIX, SEPARATOR.length);
            } else {
                localUnknown.content ~= item;
            }
        }
        if (!localUnknown.isEmpty()) {
            unknown ~= localUnknown;
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
        unknown = (Unknown[]).init;
    }



    /**
     * Determine whether the unknown container has items.
     */
    bool
    hasUnknowns () const
    {
        return unknown.length > 0;
    }
}
    }
}
