import os
import osproc
import strutils
import tables

var exc = "enter:execute(start \"\" /I $#)+abort"
var tests = newOrderedTable[string, seq[string]]()

tests[""] = @[
    getCurrentDir(), "--bind", exc % "{}", ""]

tests["-d a"] = @[
    getHomeDir()/"AppData", "--bind", exc % "{}", ""]
tests["a"] = tests["-d a"]

tests["-d c:/"] = @[
    "c:/", "--bind", exc % "{}", ""]
tests["c:/"] = tests["-d c:/"]

tests["-a 1"] = @[
    getCurrentDir(), "--bind", exc % "sc1 {}", "dir /s/b/a-d"]
tests["1"] = tests["-a 1"]

tests["-a cmd"] = @[
    getCurrentDir(), "--bind", exc % "cmd {}", ""]
tests["cmd"] = tests["-a cmd"]

tests["-d a -a 1"] = @[
    getHomeDir()/"AppData", "--bind", exc % "sc1 {}", "dir /s/b/a-d"]
tests["a 1"] = tests["-d a -a 1"]

tests["-s file"] = @[
    getCurrentDir(), "--bind", exc % "{}", "dir /s/b/a-d"]
tests["-s dir"] = @[
    getCurrentDir(), "--bind", exc % "{}", "dir /s/b/ad"]
tests["-s *.exe"] = @[
    getCurrentDir(), "--bind", exc % "{}", "dir /s/b *.exe"]

tests["-d a -a 1 -s \"dir /s/b *.exe\""] = @[
    getHomeDir()/"AppData", "--bind", exc % "sc1 {}", "dir /s/b *.exe"]
tests["a -a 1 -s \"dir /s/b *.exe\""] = tests["-d a -a 1 -s \"dir /s/b *.exe\""]
tests["-d a 1 -s \"dir /s/b *.exe\""] = tests["-d a -a 1 -s \"dir /s/b *.exe\""]
tests["a 1 -s \"dir /s/b *.exe\""] = tests["-d a -a 1 -s \"dir /s/b *.exe\""]

tests["-q query"] = @[
    getCurrentDir(), "--bind", exc % "{}", "--query", "query", ""]

tests["-d a -a 1 -s \"dir /s/b *.exe\" -q query"] = @[
    getHomeDir()/"AppData", "--bind", exc % "sc1 {}", "--query", "query", "dir /s/b *.exe"]
tests["a -a 1 -s \"dir /s/b *.exe\" -q query"] = tests["-d a -a 1 -s \"dir /s/b *.exe\" -q query"]
tests["-d a 1 -s \"dir /s/b *.exe\" -q query"] = tests["-d a -a 1 -s \"dir /s/b *.exe\" -q query"]
tests["a 1 -s \"dir /s/b *.exe\" -q query"] = tests["-d a -a 1 -s \"dir /s/b *.exe\" -q query"]

# Run tests
for test in tests.keys():
    echo "Test '$#' " % test

    var expout = tests[test].join(" : ").strip()
    var testout = execProcess("ff -t " & test).strip()

    echo "  Expected: '$#'" % expout
    echo "    Actual: '$#'" % testout

    if testout != expout:
        echo "Failed"
        quit(1)
    else:
        echo "Passed"