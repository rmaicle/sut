module sut.config;

import sut.util:
    toArray,
    unprefix;

static import sut.wrapper;
debug import std.stdio;



/**
 * Static `Config` instance.
 */
static
Config config;



/**
 * Container for the unit test configuration file and its content.
 * The file content is stored in an array.
 */
struct FileContent
{
    mixin FileContentTemplate;
}


/**
 * Container for unit test configuration file with unrecognized items.
 * The unrecognized items are stored in an array.
 */
struct Unknown
{
    mixin FileContentTemplate;
}



/**
 * Container for the contents of unit test configuration files.
 */
struct Config
{
    string[] unittests;
    string[] modules;
    Unknown[] unknown;



    /**
     * Collect unit test and module strings from unit test configuration files
     * specified in the string array argument.
     *
     * Returns: Number of non-empty files.
     */
    size_t
    collect (const string[] arg)
    {
        import std.exception: enforce;
        import std.file: exists;
        import std.format: format;

        enum FILE_NOT_FOUND = "File not found: %s";

        size_t withContent = 0;
        if (arg.length == 0) {
            return withContent;
        }
        foreach (file; arg) {
            enforce(file.exists(), format(FILE_NOT_FOUND, file));
            auto fileContent = readFile(file);
            if (fileContent.isEmpty()) {
                continue;
            }
            withContent++;
            filter(fileContent);
        }
        return withContent;
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
    hasUnknowns () const @safe
    {
        return unknown.length > 0;
    }



    /**
     * Read the contents of the file specified by the string argument.
     */
    private
    FileContent
    readFile (const string arg)
    {
        import std.file: readText;
        return FileContent(arg, arg.readText().toArray());
    }



    /**
     * Segregate file contents into their corresponding containers.
     */
    private
    bool
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
        return true;
    }
}
@("Config.readFile")
unittest {
    mixin (sut.wrapper.prologue);
    enum content = `
utb:one
utb:two
utm:first
utm:second
utb:three
utm:third
x
`;
    static import std.file;
    import std.string: strip, splitLines;

    const TestFile = std.file.tempDir() ~ "/config.test";
    const unknown = Unknown(TestFile, ["x"]);

    if (std.file.exists(TestFile)) {
        std.file.remove(TestFile);
    }
    assert (!std.file.exists(TestFile));
    std.file.write(TestFile, content);
    assert (std.file.exists(TestFile));

    Config conf;
    const fileContent = conf.readFile(TestFile);
    assert (!fileContent.isEmpty);
    conf.filter(fileContent);

    assert (conf.unittests == ["one", "three", "two"]);
    assert (conf.modules == ["first", "second", "third"]);
    assert (conf.hasUnknowns());
    assert (conf.unknown == [Unknown(TestFile, ["x"])]);

    conf.reset();
    assert (conf.unittests == (string[]).init);
    assert (conf.modules == (string[]).init);
    assert (!conf.hasUnknowns());

    std.file.remove(TestFile);
    assert (!std.file.exists(TestFile));
}



private:



/**
 * A mixin template containing a file and its content.
 */
mixin template FileContentTemplate ()
{
    string filename;
    string[] content;

    /**
     * Constructor.
     */
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
