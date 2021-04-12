module sut.util;



/**
 * Determine whether the `needle` is found in the `haystack` using the
 * specified predicate, `pred`, on how to find the `needle`.
 */
bool
isIn (alias pred)(
    const string[] haystack,
    const string needle
) {
    import std.algorithm: canFind;
    import std.uni: toLower;
    if (haystack.length == 0) {
        return false;
    }
    if (needle.length == 0) {
        return false;
    }
    return canFind!(pred)(haystack, needle);
}



/**
 * Determine whether the needle is an exact match or begins with one of
 * the items in the haystack.
 *
 * Returns: `true` if the needle is an exact match or begins with one of
 *          the items in the haystack.
 */
bool
beginsWith (
    const string[] haystack,
    const string needle
) {
    import std.algorithm: startsWith;
    import std.uni: toLower;
    return isIn!(
        (string a, string b) => b.startsWith(a.toLower))
        (haystack, needle.toLower);
}
@("beginsWith: empty")
unittest {
    //mixin (unitTestBlockPrologue());
    const string[] arr;
    assert (!arr.beginsWith(__MODULE__));
}
@("beginsWith: exact")
unittest {
    //mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.beginsWith("aaa"));
    assert (!arr.beginsWith(""));
    assert (!arr.beginsWith("any"));
}
@("beginsWith: begins with")
unittest {
    //mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.beginsWith("aaa111"));
    assert (arr.beginsWith("bbb222"));
    assert (arr.beginsWith("ccc333"));
    assert (!arr.beginsWith("111aaa"));
}



/**
 * Determine whether one of the items in the haystack is an exact match
 * or a substring of the needle.
 *
 * Returns: `true` if one of the items in the haystack is an exact match
 *          or a substring of the needle.
 */
bool
isFound (
    const string[] haystack,
    const string needle
) {
    import std.algorithm: canFind;
    import std.uni: toLower;
    return isIn!(
        (string a, string b) => b.canFind(a.toLower))
        (haystack, needle.toLower);
}
@("isFound: empty")
unittest {
    //mixin (unitTestBlockPrologue());
    const string[] arr;
    assert (!arr.isFound("aaa"));
}
@("isFound: exact")
unittest {
    //mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.isFound("aaa"));
    assert (!arr.isFound(""));
    assert (!arr.isFound("ddd"));
}
@("isFound: substring")
unittest {
    //mixin (unitTestBlockPrologue());
    const string[] arr = ["aaa", "bbb", "ccc"];
    assert (arr.isFound("aaa111"));
    assert (arr.isFound("111aaa"));
    assert (!arr.isFound(""));
    assert (!arr.isFound("ddd"));

}



/**
 * Convert string argument into array of string, stripped of whitespaces, and
 * duplicates removed.
 *
 * The function looks for '\r', '\n', '\v', '\f', "\r\n", std.uni.lineSep,
 * std.uni.paraSep and '\u0085' (NEL) as delimiters.
 *
 * Returns: `string[]`
 */
string[]
toArray (const string arg)
{
    import std.algorithm: map, remove, sort, uniq;
    import std.array: array;
    import std.string: strip, splitLines;
    import std.uni: toLower;

    if (arg.length == 0) {
        return (string[]).init;
    }
    return arg.splitLines()
        .map!(a => a.strip()).array()
        .sort!("toLower(a) < toLower(b)").release()
        .uniq().array()
        .remove!("a.length == 0").array();
}
@("toArray: empty array")
unittest {
    //mixin (unitTestBlockPrologue());
    assert ("".toArray() == []);
}
@("toArray: with empty array element")
unittest {
    //mixin (unitTestBlockPrologue());
    const arr = " one\n \n two ";
    assert (arr.toArray() == ["one", "two"]);
}
@("toArray")
unittest {
    //mixin (unitTestBlockPrologue());
    const arr = " utb:one\n utb:two \n utm:three \nutm:four\nutb:one\n   utb:two ";
    assert (arr.toArray() == ["utb:one", "utb:two", "utm:four", "utm:three"]);
}



/**
 * Sort (case insensitive) and remove duplicates.
 */
string[]
dedup (const string[] arg) {
    import std.algorithm:
        sort,
        uniq;
    import std.array: array;
    import std.uni: toLower;
    return (arg.dup).sort!("toLower(a) < toLower(b)")
        .release()
        .uniq()
        .array();
}
unittest {
    auto arr = ["one", "four", "two", "three", "two", "four", "three"];
    assert (arr.dedup() == ["four", "one", "three", "two"]);
}



/**
 * Remove needles from haystack.
 */
string[]
remove (
    const string[] haystack,
    const string[] needles
) {
    import std.algorithm:
        canFind,
        remove;
    return (haystack.dup).remove!(a => needles.canFind(a))();
}
unittest {
    auto arr = ["one", "two", "three", "four"];
    assert (arr.remove(["one"])   == ["two", "three", "four"]);
    assert (arr.remove(["two"])   == ["one", "three", "four"]);
    assert (arr.remove(["three"])   == ["one", "two", "four"]);
    assert (arr.remove(["four"])   == ["one", "two", "three"]);
}



/**
 * Filter the string array argument containing the specified prefix argument
 * irrespective of case variance.
 *
 * Returns: a sorted `string[]` without the specified prefix.
 */
string[]
unprefix (
    const string[] arg,
    const string prefix
) {
    import std.algorithm: filter, map, sort, SwapStrategy;
    import std.array: array;
    import std.string: startsWith;
    import std.uni: toLower;

    if (arg.length == 0) {
        return (string[]).init;
    }
    return arg.filter!(a => a.toLower.startsWith(toLower(prefix)))
        .map!(a => a[prefix.length..$])
        .array()
        .sort!("toUpper(a) < toUpper(b)", SwapStrategy.stable)
        .array();
}
@("unprefix: empty array")
unittest {
    //mixin (unitTestBlockPrologue());
    assert ((string[]).init.unprefix("") == []);
}
@("unprefix: with empty prefix")
unittest {
    //mixin (unitTestBlockPrologue());
    string[] arr = [
        "prefix:one",
        "PREFIX:two",
        "three",
        "four"
    ];
    assert (unprefix(arr, "") == ["four", "prefix:one", "PREFIX:two", "three"]);
}
@("unprefix")
unittest {
    //mixin (unitTestBlockPrologue());
    string[] arr = [
        "prefix:one",
        "PREFIX:two",
        "preFIX:three: name",
        "four"
    ];
    assert (unprefix(arr, "prefix:") == ["one", "three: name", "two"]);
}
