# Package

version       = "0.1.0"
author        = "genotrance"
description   = "Windows wrapper for fzf"
license       = "MIT"

bin = @["ff"]
skipDirs = @["tests"]

# Dependencies

requires "nim >= 0.16.0", "commandeer >= 0.12.1"

task release, "Build release binary":
    exec "nim c -d:release -d:VERSION=v" & version & " --opt:size ff.nim"
    exec "sleep 1"
    exec "strip -s ff.exe"
    exec "upx --best ff.exe"

task test, "Test ff":
    exec "nim c -r tests/fftest.nim"
