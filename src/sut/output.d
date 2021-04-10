module sut.output;

import sut.counter;
import sut.color;
import sut.execlist:
    isExecutionListEmpty,
    moduleExecList,
    unitTestExecList;
import sut.skiplist:
    filterSkipList = filter;

import std.string: toStringz;
import std.traits: ReturnType;

import core.stdc.stdio:
    fflush,
    printf,
    stdout;
import core.time: MonoTime;


alias Stringz = ReturnType!toStringz;

/**
 * Execution mode is the context in which the unit test is running.
 */
enum Mode: string {
    All = "All",
    Selection = "Selection"
}



/** Output labels */
enum Label: string {
    Start               = "[unittest] Start   ",
    Blank               = "[unittest]         ",
    Mode                = "[unittest] Mode:   ",
    Module              = "[unittest] Module: ",
    BlockSummary        = "[unittest] Blocks: ",
    Summary             = "[unittest] Summary:",
    End                 = "[unittest] End     ",
    AssertionFailed     = "[unittest] Assertion Failed:",
    AssertionDetail     = "           ",
    Trace               = "   [trace]"
}



enum Module: string {
    WithUnitTest = "Module(s) With Unit Test",
    WithoutUnitTest = "Module(s) Without Unit Test",
    Skipped = "Module(s) With Skipped Unit Test"
}



Mode
getExecutionMode ()
{
    version (sut) {
        return isExecutionListEmpty() ? Mode.All : Mode.Selection;
    } else {
        return Mode.All;
    }
}



void
printIntro ()
{
    version (sut) {} else {
        return;
    }
    printf("%s\n", Label.Start.toStringz);
    printMode();
    auto mode = getExecutionMode();
    if (mode != Mode.Selection) {
        return;
    }
    printSelections();
}

void
printUnitTestInfo (
    const string moduleName,
    const string unitTestName,
    const size_t line
) {
    printf("%s %s %4zd %s%s%s\n",
        Label.Blank.toStringz,
        moduleName.toStringz,
        line,
        Color.Green.toStringz,
        unitTestName.toStringz,
        Color.Reset.toStringz);
    fflush(stdout);
}



void
printModuleStart (const string arg)
{
    printf("%s %s\n", Label.Module.toStringz, arg.toStringz);
}



void
printModuleSummary (
    const string moduleName,
    const UnitTestCounter counter,
    const MonoTime from,
    const MonoTime to
) {
    const passColor = counter.isAllPassing() ? Color.IGreen : Color.Yellow;
    const skipColor = counter.isNoneSkipped() ? Color.IGreen : Color.Yellow;

    //if (counter.found > 0 &&
    printf("%s %s - %s%zd passed%s, %s%zd skipped%s, %zd found - %.3fs\n",
        Label.Blank.toStringz,
        moduleName.toStringz,
        passColor.toStringz,
        counter.passing,
        Color.Reset.toStringz,
        skipColor.toStringz,
        counter.skipped,
        Color.Reset.toStringz,
        counter.total,
        (to - from).total!"msecs" / 1000.0);
}



//void
//printSkippedModuleSummary (
//    const string moduleName,
//    const UnitTestCounter counter,
//    const MonoTime from,
//    const MonoTime to
//) {
//    const passedColor = counter.pass == counter.found ? Color.IGreen : Color.Yellow;
//    const skipColor = counter.skip == 0 ? Color.IGreen : Color.Yellow;

//    printf("%s %s - %s%zd passed%s, %s%zd skipped%s, %zd found - %.3fs\n",
//        Label.Blank.toStringz,
//        moduleName.toStringz,
//        passedColor.toStringz,
//        counter.pass,
//        Color.Reset.toStringz,
//        skipColor.toStringz,
//        counter.skip,
//        Color.Reset.toStringz,
//        counter.found,
//        (to - from).total!"msecs" / 1000.0);
//}



void
printSummary (
    const UnitTestCounter counter,
    const size_t moduleCount,
    const string[] withUnitTestModules,
    const string[] skippedModules,
    const string[] noUnitTestModules
) {
    import std.uni: toLower;

    const passColor = counter.isAllPassing() ? Color.IGreen : Color.Yellow ;
    const failColor = counter.isNoneFailing() ? Color.IGreen: Color.IRed ;
    const skipColor = counter.isNoneSkipped() ? Color.IGreen : Color.Yellow ;

    printf("\n%s %s%zd passed%s, %s%zd failed%s, %s%zd skipped%s, %zd found\n",
        Label.BlockSummary.toStringz,
        passColor.toStringz, counter.passing, Color.Reset.toStringz,
        failColor.toStringz, counter.failing, Color.Reset.toStringz,
        skipColor.toStringz, counter.skipped, Color.Reset.toStringz,
        counter.total);

    printf("%s %zd %s\n",
        Label.Summary.toStringz,
        moduleCount,
        Module.WithUnitTest.toLower.toStringz);
    auto blank = Label.Blank.toStringz;
    printf("%s %zd %s\n",
        blank,
        skippedModules.length,
        Module.WithoutUnitTest.toLower.toStringz);
    printf("%s %zd %s\n",
        blank,
        skippedModules.length,
        Module.Skipped.toLower.toStringz);

    if (getExecutionMode() == Mode.Selection) {
        return;
    }

    printSummaryWithUnitTests(withUnitTestModules);
    printSummaryWithSkippedUnitTests(skippedModules);
    printSummaryWithoutUnitTests(noUnitTestModules);
    printf("%s\n", Label.End.toStringz);
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
    // Display stack trace; indent for alignment only
    foreach (i, item; throwable.info) {
        if (i <= 1) {
            continue;
        }
        if (item.canFind(".__unittest_L")) {
            printf("%s %s%s%s\n",
                Label.Trace.toStringz,
                Color.Yellow.toStringz,
                item.toStringz,
                Color.Reset.toStringz);
        } else {
            printf("%s %s\n", Label.Trace.toStringz, item.toStringz);
        }
    }
}



private:



void
printSummaryWithUnitTests (const string[] arg)
{
    printSummaryCategory(arg, Module.WithUnitTest, Color.IGreen, Color.IRed);
}



void
printSummaryWithSkippedUnitTests (const string[] arg)
{
    // Note the reversed color arguments
    printSummaryCategory(arg, Module.Skipped, Color.Yellow, Color.IGreen);
}



void
printSummaryWithoutUnitTests (const string[] arg)
{
    printSummaryCategory(arg, Module.WithoutUnitTest, Color.Yellow, Color.IGreen);
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
        Label.Blank.toStringz,
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
printMode ()
{
    auto mode = getExecutionMode();
    printf("%s %s\n", Label.Mode.toStringz, mode.toStringz);
}



void
printSelections ()
{
    const label = Label.Blank.toStringz;
    foreach (entry; moduleExecList) {
        printf("%s   module: %s\n", label, entry.toStringz);
    }
    foreach (entry; unitTestExecList) {
        printf("%s   block:  %s\n", label, entry.toStringz);
    }
}
