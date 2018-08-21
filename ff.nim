import commandeer, os, osproc, parsecfg, streams, strscans, strutils, tables

const
  VERSION {.strdefine.} = ""

  DOC = """
ff $#
Windows wrapper for fzf

Usage:
  ff [options] [<short1>] [<short2>]

Options:
  -d <dir>        Directory to index or shortcut from config file
  -s <select>     Content to populate the fzf menu
                    file, dir or *.xyz shortcuts
                    or command to execute
  -a <action>     Action to execute or shortcut from config file
  -q <query>      Prefill query for fzf

  -c <config>     Configuration file
  -h              This help menu

Shortcut arguments:
  short1          dir shortcut if matches
                  action shortcut if matches
                  dir if directory exists
                  else action
  short1 short2   short1 = dir shortcut or dir if exists
                  short2 = action shortcut or action

  Explicit -d or -a will override any shortcut arguments

""" % VERSION

proc parseConfig(help=false): string

commandline:
    arguments(SHORTCUT, string, false)

    option(DIR, string, "dir", "d", getCurrentDir())
    option(SELECT, string, "select", "s", "")
    option(ACTION, string, "action", "a", "{}")
    option(QUERY, string, "query", "q", "")

    option(CONFIGFILE, string, "config", "c", getAppDir()/"ff.cfg")
    option(TEST, bool, "test", "t", false)
    exitoption("help", "h", parseConfig(true))

var CONFIG: Config

proc fzf() =
    var act = ACTION
    if not ("{}" in ACTION):
        act &= " {}"

    var args = @["--bind", "enter:execute(start \"\" /I $#)+abort" % act]
    if QUERY != "":
        args.add("--query")
        args.add(QUERY)

    if not TEST:
        var
          line: string
          pin: Process    # FZF
          pout: Process   # SELECT
          sin: Stream
          sout: Stream

        if SELECT.len() != 0:
          pin = startProcess("fzf", DIR, args, options={poUsePath})
          sin = pin.inputStream()

          pout = startProcess(SELECT, DIR, options={poUsePath, poEvalCommand, poStdErrToStdOut})
          sout = pout.outputStream()

          try:
            while true:
              if pout.running():
                line = sout.readLine()
              else:
                break

              if pin.running():
                sin.writeLine(line)
              else:
                break
          except IOError, OSError:
            discard

          sout.close()
          sin.close()

          if pout.running():
            pout.kill()

          discard pout.waitForExit()
        else:
          pin = startProcess("fzf", DIR, args, options={poUsePath, poParentStreams})

        discard pin.waitForExit()
    else:
        stdout.write DIR & " : "
        for arg in args:
            stdout.write arg & " : "

proc replaceEnv(str: var string): string =
    var env: string
    while "$" in str:
        let pos = str.find("$")
        if str[pos..<str.len].scanf("$$$w", env):
            if existsEnv(env):
                str = str.replace("$" & env, getEnv(env))
            else:
                echo "Missing environment variable: $" & env
                quit(1)

    return str.replace("/", $DirSep).replace("\\", $DirSep)

proc dirFind(dir: string, fail = false): string =
    var dirout = dir
    # Expand directory shortcut
    if CONFIG.hasKey("directories") and CONFIG["directories"].hasKey(dirout):
        dirout = CONFIG["directories"][dirout].replaceEnv()

    if not dirExists(dirout):
        if fail:
            echo "Directory doesn't exist: " & dirout
            quit(1)
        return ""

    return dirout

proc actionFind(action, select: string): tuple[actionout, selectout: string] =
    var actionout = action
    var selectout = select

    # Expand action shortcut
    if CONFIG.hasKey("actions") and CONFIG["actions"].hasKey(actionout & ".action"):
        if selectout == "" and CONFIG["actions"].hasKey(actionout & ".select"):
            selectout = CONFIG["actions"][actionout & ".select"]
        actionout = CONFIG["actions"][actionout & ".action"]

    # Expand SELECT shortcuts
    if selectout != "":
        if selectout == "file":
            selectout = "cmd /c dir /s/b/a-d"
        elif selectout == "dir":
            selectout = "cmd /c dir /s/b/ad"
        elif selectout.find("*") != -1 and selectout.find(" ") == -1:
            selectout = "cmd /c dir /s/b " & selectout

    return (actionout, selectout)

proc parseConfig(help=false): string =
    # Load config file
    if fileExists(CONFIGFILE):
        CONFIG = loadConfig(CONFIGFILE)
    else:
        CONFIG = newConfig()

    # List configuration if help
    if help or len(SHORTCUT) > 2:
        var helpout = DOC

        if fileExists(CONFIGFILE):
            helpout &= "Configuration file: \n  " & CONFIGFILE & "\n\n"

        if CONFIG.hasKey("directories"):
            helpout &= "Directory shortcuts:\n"
            for i in CONFIG["directories"].keys():
                helpout &= "  " & i & " = " & CONFIG["directories"][i].replaceEnv() & "\n"
            helpout &= "\n"

        if CONFIG.hasKey("actions"):
            helpout &= "Action shortcuts:"
            for i in CONFIG["actions"].keys():
                var nv = i.split(".")
                if len(nv) != 2:
                    echo "Bad configuration key: " & i
                    quit(1)
                if nv[1] == "name":
                    helpout &= "\n  " & nv[0] & " = " & CONFIG["actions"][i]
                elif nv[1] == "select":
                    helpout &= "\n      Select: " & CONFIG["actions"][i]
                elif nv[1] == "action":
                    helpout &= "\n      Action: " & CONFIG["actions"][i]
                    if not ("{}" in CONFIG["actions"][i]):
                        helpout &= " {}"
        
        return helpout

    # Expand -d and -a
    DIR = dirFind(DIR, true)
    (ACTION, SELECT) = actionFind(ACTION, SELECT)
    
    # Analyze shortcuts
    var short1 = ""
    var short2 = ""
    if len(SHORTCUT) > 0:
        short1 = SHORTCUT[0]
    if len(SHORTCUT) > 1:
        short2 = SHORTCUT[1]

    if short1 != "":
        # short1 has to be directory or dir shortcut
        if short2 != "":
            # Expand dir if -d not specified
            if DIR == getCurrentDir():
                DIR = dirFind(short1, true)

            # Expand action if -a not specified
            if ACTION == "{}":
                (ACTION, SELECT) = actionFind(short2, SELECT)
        else:
            # Could be directory
            # Expand dir if -d not specified
            if DIR == getCurrentDir():
                var d = dirFind(short1)
                # Didn't work, maybe action if -a not specified
                if d == "" and ACTION == "{}":
                    (ACTION, SELECT) = actionFind(short1, SELECT)
                else:
                    DIR = d
            else:
                # -d specified, so must be action if -a not specified
                if ACTION == "{}":
                    (ACTION, SELECT) = actionFind(short1, SELECT)

    return ""

var helpout = parseConfig()
if helpout != "":
    echo helpout
else:
    fzf()
