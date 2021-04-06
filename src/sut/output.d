module sut.output;

import sut.counter;
import sut.color;
import sut.execlist:
    isExecutionListEmpty,
    moduleExecList,
    unitTestExecList;
import sut.skiplist: filterSkipList = filter;

import std.string: toStringz;

import core.stdc.stdio: printf;
import core.time: MonoTime;



/** Output labels */
enum Label: string {
    Mode                = "[unittest] Mode:   ",
    ModeSelective       = "[unittest]         ",
    Module              = "[unittest] Module: ",
    ModuleSummary       = "[unittest] Modules:",
    BlockSummary        = "[unittest] Blocks: ",
    NoGroupLabel        = "[unittest]         ",
    AssertionFailed     = "[unittest] Assertion Failed:",
    AssertionDetail     = "           ",
    Trace               = "   [trace]"
}

enum Module: string {
    WithUnitTest = "Modules With Unit Test:",
    WithoutUnitTest = "Modules Without Unit Test:",
    Skipped = "Modules With Skipped Unit Test:"
}






void
printUnitTestMode ()
{
    enum Mode: string {
        All = "All",
        Selection = "Selection"
    }
    version (sut) {
        Mode mode = isExecutionListEmpty ? Mode.All : Mode.Selection;
    } else {
        Mode mode = Mode.All;
    }
    printf("%s %s\n", Label.Mode.toStringz, mode.toStringz);
    version (sut) {
        const string label = Label.ModeSelective;
        foreach (entry; moduleExecList) {
            printf("%s   module: %s\n", label.toStringz, entry.toStringz);
        }
        foreach (entry; unitTestExecList) {
            printf("%s   block:  %s\n", label.toStringz, entry.toStringz);
        }
    }
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
    const passedColor = counter.pass == counter.found ? Color.IGreen : Color.Yellow;
    const skipColor = counter.skip == 0 ? Color.IGreen : Color.Yellow;

    printf("%s %s - %s%zd passed%s, %s%zd skipped%s, %zd found - %.3fs\n",
        Label.NoGroupLabel.toStringz,
        moduleName.toStringz,
        passedColor.toStringz,
        counter.pass,
        Color.Reset.toStringz,
        skipColor.toStringz,
        counter.skip,
        Color.Reset.toStringz,
        counter.found,
        (to - from).total!"msecs" / 1000.0);
}



void
printSummary (
    const UnitTestCounter counter,
    const size_t moduleCount,
    const string[] withUnitTestModules,
    const string[] skippedModules,
    const string[] noUnitTestModules
) {
    const passColor = counter.pass == counter.found ? Color.IGreen : Color.Yellow ;
    const failColor = counter.fail > 0 ? Color.IRed : Color.IGreen ;
    const skipColor = counter.skip == 0 ? Color.IGreen : Color.Yellow ;

    printf("\n%s %s%zd passed%s, %s%zd failed%s, %s%zd skipped%s, %zd found\n",
        Label.BlockSummary.toStringz,
        passColor.toStringz, counter.pass, Color.Reset.toStringz,
        failColor.toStringz, counter.fail, Color.Reset.toStringz,
        skipColor.toStringz, counter.skip, Color.Reset.toStringz,
        counter.found);

    printf("%s %zd With, %zd with skipped, %zd without\n",
        Label.ModuleSummary.toStringz,
        moduleCount,
        skippedModules.length,
        noUnitTestModules.length);

    if (!isExecutionListEmpty) {
        return;
    }

    printModulesWithUnitTests(withUnitTestModules);
    printModulesWithSkippedUnitTests(skippedModules);
    printModulesWithoutUnitTests(noUnitTestModules);
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
printModulesWithUnitTests (const string[] arg)
{
    perModule(arg, Module.WithUnitTest, Color.IGreen, Color.IRed);
}



void
printModulesWithSkippedUnitTests (const string[] arg)
{
    // Note the reversed color arguments
    perModule(arg, Module.Skipped, Color.IRed, Color.IGreen);
}



void
printModulesWithoutUnitTests (const string[] arg)
{
    perModule(arg, Module.WithoutUnitTest, Color.Yellow, Color.IGreen);
}



void
perModule (
    const string[] list,
    const string label,
    const string goodColor,
    const string badColor)
{
    import std.algorithm: sort;
    const color = list.length == 0 ? badColor : goodColor;
    printf("%s %s%s %zd%s\n",
        Label.NoGroupLabel.toStringz,
        color.toStringz,
        label.toStringz,
        list.length,
        Color.Reset.toStringz);
    if (list.length > 0) {
        foreach (e; (list.dup).sort.release()) {
            printf("%s   %s%s%s\n",
                Label.NoGroupLabel.toStringz,
                color.toStringz,
                e.toStringz,
                Color.Reset.toStringz);
        }
    }
}
