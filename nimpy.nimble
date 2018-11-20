version       = "0.1.0"
author        = "Yuriy Glukhov"
description   = "Nim python integration lib"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.0"

import oswalkdir, ospaths, strutils

task test, "Run tests":
    let pluginExtension = when defined(windows): "pyd" else: "so"

    for f in walkDir("tests"):
        # Compile all nim modules, except those starting with "t"
        let sf = f.path.splitFile()
        if sf.ext == ".nim" and not sf.name.startsWith("t"):
            exec "nim c --app:lib --out:" & f.path.changeFileExt(pluginExtension) & " " & f.path

    mvFile("tests/custommodulename".changeFileExt(pluginExtension), "tests/_mycustommodulename".changeFileExt(pluginExtension))

    for f in walkDir("tests"):
        # Run all python modules starting with "t"
        let sf = f.path.splitFile()
        if sf.ext == ".py" and sf.name.startsWith("t"):
            exec "python2 " & f.path
            exec "python3 " & f.path

    for f in walkDir("tests"):
        # Run all nim modules starting with "t"
        let sf = f.path.splitFile()
        if sf.ext == ".nim" and sf.name.startsWith("t"):
            exec "nim c -r " & f.path
