```ff``` is a Windows wrapper for [fzf](https://github.com/junegunn/fzf)

```fzf``` is very well integrated into *Nix environments but integration into Windows is relatively [limited](https://github.com/junegunn/fzf/wiki/Windows). ```ff``` aims to improve the experience of using ```fzf``` on Windows and simplify various routine tasks.

![Preview](ff.gif?raw=true "Preview")

__Installation__

```ff``` is built in [Nim](https://www.nim-lang.org) and can be obtained in various ways.

* Download the pre-built binary from the [Releases](https://github.com/genotrance/ff/releases) page
* Via the [Nimble](https://github.com/nim-lang/nimble#installation) package manager

    ```
    nimble install https://github.com/genotrance/ff
    ```

* Compile from source - you will require the [Nim](https://nim-lang.org/install_windows.html) compiler and the  ```commandeer``` module which can be installed via ```nimble install commandeer``` or downloaded directly from [Github](https://github.com/fenekku/commandeer).

    ```
    git clone https://github.com/genotrance/ff
    cd ff
    nim c -d:release ff.nim
    ```

Simply place the compiled binary in the system path along with ```fzf```. Also copy ```ff.cfg``` to add some common directory and action shortcuts.

The included [AutoHotKey](https://autohotkey.com) script [ff.ahk](ff.ahk) can speed up things even more. It will register the ```WIN-/``` hotkey and allow calling ```ff``` with upto two shortcuts. E.g. ```WIN-/ x c``` => ```ff x c```. A single shortcut can be provided by hitting ```ENTER``` for the second one.

__Usage__

```
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
```

```ff``` helps speed up the process of providing the following to parameters to ```fzf```.

_Base directory_

The base directory used by ```fzf``` can be specified via ```ff``` so that only that directory is indexed. Given how fast ```fzf``` is in general, this does not have to be too specific but running on the root directory isn't really sensible either.

The base directory can be explicitly specified on the command line or reference a shortcut defined in ```ff.cfg```. A few standard shortcuts are defined to get started.

```
ff                         run in currect directory
ff -d c:\Users             full path to directory specified
ff -d ..\test              relative directory
ff -d d                    shortcut d = current user's desktop, defined in ff.cfg
```

Using ```<short1>``` for directory skipping the explicit ```-d```:

```
ff c:\Users
ff ..\test
ff d                       
```

Base directory may not be applicable for some selection/action combinations and can be safely ignored. The currect directory will be used by default.

_Selection_

```fzf``` by default finds and displays all the files and folders in the directory it is run. This selection can be changed via the ```ff``` command line or by piping command output to ```ff```.

```
ff -s file                 Select only files in the menu
ff -s dir                  Select only directories
ff -s *.exe                Select only executables
ff -s tasklist             Select the output of the tasklist command
```

Piping command output instead of using ```-s```:

```
dir /s/b/a-d | ff
dir /s/b/ad | ff
dir /s/b *.exe | ff
tasklist | ff
```

Selections can also be defined as part of an action definition in ```ff.cfg``` since an action might only apply on specific items. E.g. you can only ```cd``` into a directory and not a file. However, if a selection is specified using ```-s```, it will take precedence over any shortcut definition. Further, any command output piped into ```ff``` will take precedence over ```-s``` or shortcut definitions.

_Action_

Once a specific selection has been made within ```fzf```, some action will need to be performed on that selection. This can be specified on the ```ff``` command line explicitly or reference a shortcut defined in ```ff.cfg```. A few standard actions are provided to get started.

```
ff                         default action - let Windows decide
ff -a gvim                 gvim {file}, assuming gvim is in the path
ff -a "c:\test.exe -t"     run executable providing full path and flags
ff -a c                    shortcut c = open a cmd.exe on selected directory
```

Using ```<short1>``` for action skipping the explicit ```-a```:
```
ff gvim
ff "c:\test.exe -t"
ff c
```

Using ```<short2>``` for action:
```
ff d gvim
ff d "c:\test.exe -t"
ff d c
```

As mentioned earlier, action shortcuts in ```ff.cfg``` can define a corresponding selection which will be used for that action.

_Query_

```fzf``` allows prefilling the query filter and ```ff``` allows passing through such a query on the command line for convenience. 

```
ff -q query
```

_Configuration file_

If ```ff.cfg``` isn't in the same directory as ```ff```, it can be provided via the command line using the -c flag.

```
ff -c config.cfg
```

__Configuration__

The ```ff.cfg``` file has a simple syntax and is quite obvious.

_[directories]_

This section can be used to add base directory shortcuts that can be easily invoked from ```ff```.

```
[directories]
key = "directory path"
d = "$USERPROFILE/Desktop"
```

Key can be any string, although the shorter it is, the faster it is to type. Environment variables can be referenced using the $XYZ syntax.

_[actions]_

This section defines actions that can be performed once an item is selected within ```fzf```.

```name``` - sub-key used to optionally describe the shortcut

```select``` - sub-key used to optionally define a custom selection within ```fzf``` for this action

```action``` - sub-key used to define the command to execute once item is selected within ```fzf```

```
[actions]
key.name = "Simple description of the shortcut"
key.select = "Command to run for selection"
key.action = "Command to execute on selected item"

c.name = "Open Console window in selected directory"
c.select = "dir"
c.action = "cmd /k cd"
```

__Feedback__

ff is a work in progress and any feedback or suggestions are welcome. It is hosted on [GitHub](https://github.com/genotrance/ff) with an MIT license so issues, forks and PRs are most appreciated.
