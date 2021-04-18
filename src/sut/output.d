module sut.output;

import sut.config:
    Config,
    Unknown;
import sut.counter: UnitTestCounter;
import sut.execution: executionList;
import sut.util: beginsWith;

import std.string: toStringz;
import std.traits: ReturnType;

import core.stdc.stdio:
    fflush,
    printf,
    stdout;
import core.time: MonoTime;



void
printIntro ()
{
    static import std.compiler;

    printDateTime(Label.Start);
    printf("%s %s version %d.%d\n",
        Label.Blank.toStringz,
        std.compiler.name.toStringz,
        std.compiler.version_major,
        std.compiler.version_minor);
    printf("%s D specification version %d\n",
        Label.Blank.toStringz,
        std.compiler.D_major);
    auto mode = getExecutionMode();
    printf("%s %s\n", Label.Mode.toStringz, mode.toStringz);
    if (mode != ExecutionMode.Selection) {
        return;
    }
    printSelections();
}



void
printUnknownSelections (const Config arg)
{
    enum UNKNOWN_FMTS = "%s   x:      %s (%s)\n";
    const label = Label.Blank.toStringz;
    if (!arg.hasUnknowns()) {
        return;
    }
    foreach (file; arg.unknown) {
        const filename = file.filename.toStringz;
        foreach (item; file.content) {
            printf(UNKNOWN_FMTS, label, item.toStringz, filename);
        }
    }
}



void
printUnitTestInfo (
    const string moduleName,
    const string unitTestName,
    const size_t line,
    const UnitTestCounter counter
) {
    version (sut) {
        string label;
        if (counter.current.total == 1) {
            label = Label.Module;
        } else {
            label = Label.Blank;
        }

        printf("%s %s %4zd %s%s%s\n",
            label.toStringz,
            moduleName.toStringz,
            line,
            Color.Green.toStringz,
            unitTestName.toStringz,
            Color.Reset.toStringz);
        fflush(stdout);
    }
}



void
printModuleSummary (
    const string moduleName,
    const UnitTestCounter counter,
    const MonoTime from,
    const MonoTime to
) {
    const passColor = counter.current.isAllPassing() ? Color.IGreen : Color.Yellow;
    const failingColor = counter.current.isNoneFailing() ? Color.IGreen : Color.IRed;

    printf("%s %s - %s%zd passed%s, %s%zd failed%s, %zd found - %.3fs\n",
        Label.Blank.toStringz,
        moduleName.toStringz,
        passColor.toStringz,
        counter.current.passing,
        Color.Reset.toStringz,
        failingColor.toStringz,
        counter.current.failing,
        Color.Reset.toStringz,
        counter.current.total,
        (to - from).total!"msecs" / 1000.0);
}



void
printSummary (
    const UnitTestCounter counter,
    const string[] excludeList,
) {
    import std.uni: toLower;

    const passColor = counter.all.isAllPassing() ? Color.IGreen : Color.Yellow ;
    const failColor = counter.all.isNoneFailing() ? Color.IGreen: Color.IRed ;

    printf("\n%s %s%zd passed%s, %s%zd failed%s, %zd found\n",
        Label.Summary.toStringz,
        passColor.toStringz, counter.all.passing, Color.Reset.toStringz,
        failColor.toStringz, counter.all.failing, Color.Reset.toStringz,
        counter.all.total);

    auto blank = Label.Blank.toStringz;
    printf("%s %zd %s\n",
        blank,
        counter.modulesWith.length,
        Module.WithUnitTest.toLower.toStringz);
    printf("%s %zd %s\n",
        blank,
        counter.modulesWithout.length,
        Module.WithoutUnitTest.toLower.toStringz);
    printf("%s %zd %s\n",
        blank,
        excludeList.length,
        Module.Excluded.toLower.toStringz);

    printSummaryWithUnitTests(counter.modulesWith, counter.modulesWithPrologue);
    printSummaryWithoutUnitTests(counter.modulesWithout);
    printSummaryExcludedUnitTests(excludeList);

    printf("%s %s\n", Label.End.toStringz, getCurrentTimeString().toStringz);
    fflush(stdout);
}



void
printAssertion (
    const string moduleName,
    const Throwable throwable
) {
    import std.algorithm:
        canFind,
        startsWith;
    import std.conv: to;

    enum COLUMN_MAX = 70;
    enum SEPARATOR = 1;
    enum INDENT = 5;
    enum SPACE_CHAR = ' ';

    enum PREFIX = "??:?";
    enum UNIT_TEST_FUNC = ".__unittest_L";

    // Ignore custom unit test runner internals.

    enum IGNORE_START = "sut.runner.customUnitTestRunner().";
    enum IGNORE_END = "sut.runner.customUnitTestRunner()";
    // Performance consideration we do not want to call canFind everytime
    // so we use boolean flags for checking.
    bool isIgnoreStartFound = false;
    bool isIgnoreEndFound = false;

    // Display assertion information
    printf("%s%s%s\n%s%s\n%sModule: %s (%zd)\n%sFile: %s (%zd)\n",
        Color.IRed.toStringz,
        Label.AssertionFailed.toStringz,
        Color.Reset.toStringz,
        Label.AssertionDetail.toStringz,
        throwable.message.toStringz,
        Label.AssertionDetail.toStringz,
        moduleName.toStringz,
        throwable.line,
        Label.AssertionDetail.toStringz,
        throwable.file.toStringz,
        throwable.line,);


    string line;
    // Display stack trace; indent for alignment only
    foreach (i, item; throwable.info) {
        if (i == 0) {
            continue;
        }
        line = to!string(item);
        if (line.startsWith(PREFIX)) {
            line = line[PREFIX.length + 1 .. $];
        }
        if (line.canFind(UNIT_TEST_FUNC)) {
            printf("%s %s%s%s\n",
                Label.Trace.toStringz,
                Color.Yellow.toStringz,
                line.toStringz,
                Color.Reset.toStringz);
            continue;
        }
        // Do not output stack trace items beyond the call to the
        // custom unit test runner.
        if (!isIgnoreStartFound && line.canFind(IGNORE_START)) {
            printf("%s ...  (skipping)\n", Label.Trace.toStringz);
            isIgnoreStartFound = true;
            continue;
        }
        if (!isIgnoreEndFound && line.canFind(IGNORE_END)) {
            isIgnoreEndFound = true;
            continue;
        }
        if (isIgnoreStartFound ^ isIgnoreEndFound) {
            continue;
        }
        printf("%s %s\n", Label.Trace.toStringz, line.toStringz);
    }
    fflush(stdout);
}



private:



/**
 * Execution mode is the context in which the unit test is running.
 */
enum ExecutionMode: string {
    All = "All",
    Selection = "Selection"
}



/** Output labels */
enum Label: string {
    Start               = "[unittest] Start   ",
    Blank               = "[unittest]         ",
    Mode                = "[unittest] Mode:   ",
    Module              = "[unittest] Module: ",
    Summary             = "[unittest] Summary:",
    List                = "[unittest] List:   ",
    End                 = "[unittest] End     ",
    AssertionFailed     = "[unittest] Assertion Failed:",
    AssertionDetail     = "           ",
    Trace               = "   [trace]"
}



/**
 * Labels for the summary lists.
 */
enum Module: string {
    WithUnitTest = "Module(s) with unit test",
    WithoutUnitTest = "Module(s) without unit test",
    Excluded = "Module(s) excluded"
}



/** Color definitions. */
enum Color: string {
    Reset   = "\033[0;;m",
    Red     = "\033[0;31m",
    IRed    = "\033[38;5;196m",
    Green   = "\033[0;32m",
    IGreen  = "\033[38;5;46m",
    Yellow  = "\033[0;93m",
    White   = "\033[0;97m"
}



/**
 * Determine the `ExecutionMode` based on the execution list status.
 * The `ExecutionMode` is `Selective` if the execution list is not
 * empty. Otherwise, `ExecutionMode` is `All`.
 */
ExecutionMode
getExecutionMode ()
{
    if (executionList.isEmpty()) {
        return ExecutionMode.All;
    } else {
        return ExecutionMode.Selection;
    }
}



string
getCurrentTimeString ()
{
    import std.datetime: Clock;
    return Clock.currTime().toSimpleString();
}


void
printSummaryWithUnitTests (
    const string[] modulesWithUnitTests,
    const string[] modulesWithPrologue
) {
    import std.algorithm: sort;

    alias GoodColor = Color.IGreen;
    alias BadColor = Color.IRed;
    const AttentionColor = Color.Yellow.toStringz;
    const ResetColor = Color.Reset.toStringz;
    const color = modulesWithUnitTests.length == 0 ? BadColor : GoodColor;

    printf("%s %s%s (%zd)%s\n",
        Label.List.toStringz,
        color.toStringz,
        Module.WithUnitTest.toStringz,
        modulesWithUnitTests.length,
        Color.Reset.toStringz);
    printf("%s Module(s) without prologue code have asterisk (*)\n",
        Label.Blank.toStringz);

    if (modulesWithUnitTests.length == 0) {
        return;
    }

    foreach (item; (modulesWithUnitTests.dup).sort.release()) {
        if (modulesWithPrologue.beginsWith(item)) {
            printf("%s     %s\n", Label.Blank.toStringz, item.toStringz);
        } else {
            printf("%s     %s%s *%s\n",
                Label.Blank.toStringz,
                AttentionColor,
                item.toStringz,
                ResetColor);
        }
    }
}



void
printSummaryWithoutUnitTests (const string[] arg)
{
    printSummaryCategory(arg, Module.WithoutUnitTest, Color.Yellow, Color.IGreen);
}



void
printSummaryExcludedUnitTests (const string[] arg)
{
    // Note the reversed color arguments
    printSummaryCategory(arg, Module.Excluded, Color.Yellow, Color.IGreen);
}



void
printSummaryCategory (
    const string[] list,
    const string label,
    const string goodColor,
    const string badColor)
{
    import std.algorithm: sort;
    const color = list.length == 0 ? badColor : goodColor;
    printf("%s %s%s (%zd)%s\n",
        Label.List.toStringz,
        color.toStringz,
        label.toStringz,
        list.length,
        Color.Reset.toStringz);
    if (list.length == 0) {
        return;
    }
    foreach (e; (list.dup).sort.release()) {
        printf("%s     %s\n", Label.Blank.toStringz, e.toStringz);
    }
}



void
printSelections ()
{
    const label = Label.Blank.toStringz;
    foreach (entry; executionList.modules) {
        printf("%s   module: %s\n", label, entry.toStringz);
    }
    foreach (entry; executionList.unittests) {
        printf("%s   block:  %s\n", label, entry.toStringz);
    }
}
