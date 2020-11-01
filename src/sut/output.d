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
    NoGroupLabel        = "[unittest]         ",
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
    version (sut) {
        Mode mode = isExecListEmpty ? Mode.All : Mode.Selection;
    } else {
        Mode mode = Mode.All;
    }
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
    string[] withUnitTestModules,
    string[] skippedModules,
    string[] noUnitTestModules
) {
    import std.algorithm: sort;

    const passColor = counter.pass == counter.found ? Color.IGreen : Color.Yellow ;
    const skipColor = counter.skip == 0 ? Color.IGreen : Color.Yellow ;

    printf("\n%s %s%zd passed%s, %s%zd skipped%s, %zd found\n",
        Label.BlockSummary.toStringz,
        passColor.toStringz, counter.pass, Color.Reset.toStringz,
        skipColor.toStringz, counter.skip, Color.Reset.toStringz,
        counter.found);

    printf("%s %zd With, %zd with skipped, %zd without\n",
        Label.ModuleSummary.toStringz,
        moduleCount,
        skippedModules.length,
        noUnitTestModules.length);

    void
    perModule (
        string[] list,
        const string label,
        const string goodColor,
        const string badColor)
    {
        const color = list.length == 0 ? badColor : goodColor;
        printf("%s %s%s %zd%s\n",
            Label.NoGroupLabel.toStringz,
            color.toStringz,
            label.toStringz,
            list.length,
            Color.Reset.toStringz);
        if (list.length > 0) {
            list.sort;
            foreach (e; list) {
                printf("%s   %s%s%s\n",
                    Label.NoGroupLabel.toStringz,
                    color.toStringz,
                    e.toStringz,
                    Color.Reset.toStringz);
            }
        }
    }

    perModule(withUnitTestModules, "Modules With Unit Test:", Color.IGreen, Color.IRed);
    perModule(skippedModules, "Modules With Skipped Unit Test:", Color.IRed, Color.IGreen);
    perModule(noUnitTestModules, "Modules Without Unit Test:", Color.IRed, Color.IGreen);
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
