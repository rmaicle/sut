module sut.output;

import sut.counter;
import sut.color;
import sut.execlist: isExecListEmpty, moduleExecList, unitTestExecList;

import std.string: toStringz;

import core.stdc.stdio: printf;
import core.time: MonoTime;



/** Output labels */
enum Label: string {
    Mode                = "[unittest] Mode:   ",
    ModeSelective       = "[unittest]         ",
    Module              = "[unittest] Module: ",
    Block               = "[unittest]      @: ",
    ModuleSummary       = "[unittest] Modules:",
    BlockSummary        = "[unittest] Blocks: ",
    SkippedUnitTestInit = "[unittest] Skipped:",
    SkippedUnitTestNext = "[unittest]         ",
    AssertionFailed     = "[unittest] Assertion Failed:",
    AssertionDetail     = "           ",
    Trace               = "   [trace]"
}




void
printUnitTestMode ()
{
    enum Mode: string {
        All = "All",
        Selection = "Selection"
    }
    Mode mode = isExecListEmpty ? Mode.All : Mode.Selection;
    printf("%s %s\n", Label.Mode.toStringz, mode.toStringz);
    version (sut) {
        foreach (entry; moduleExecList) {
            printf("%s   module: %s\n", Label.ModeSelective.toStringz, entry.toStringz);
        }
        foreach (entry; unitTestExecList) {
            printf("%s   block:  %s\n", Label.ModeSelective.toStringz, entry.toStringz);
        }
    }
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
        Label.Module.toStringz,
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
    string[] skippedModules
) {
    import std.algorithm: sort;

    const passColor = counter.pass == counter.found ? Color.IGreen : Color.Yellow ;
    const skipColor = counter.skip == 0 ? Color.IGreen : Color.Yellow ;

    printf("\n%s %s%zd passed%s, %s%zd skipped%s, %zd found\n",
        Label.BlockSummary.toStringz,
        passColor.toStringz, counter.pass, Color.Reset.toStringz,
        skipColor.toStringz, counter.skip, Color.Reset.toStringz,
        counter.found);

    if (counter.skip == 0) {
        printf("%s %zd (total)\n", Label.ModuleSummary.toStringz, moduleCount);
    } else {
        printf("%s %zd (total), %zd skipped\n",
            Label.ModuleSummary.toStringz,
            moduleCount,
            counter.skip);
        skippedModules.sort;
        foreach (e; skippedModules) {
            printf("%s   %s\n", Label.SkippedUnitTestNext.toStringz, e.toStringz);
        }
    }
}



void
printAssertion (
    const string moduleName,
    const Throwable throwable
) {
    import std.algorithm: startsWith;

    // Display assertion information
    printf("%s%s%s\n%s%s\n%s%s (%zd)\n%s%s (%zd)\n",
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
        auto info = item.startsWith("/home") ? item[32..$] : item;
        printf("%s %s\n", Label.Trace.toStringz, info.toStringz);
    }
}
