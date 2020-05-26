version     = "0.1.0"
author      = "Yuriy Glukhov"
description = "Nim python integration lib"
license     = "MIT"

# Dependencies

requires "nim >= 0.17.0"

import oswalkdir, os, strutils

proc calcPythonExecutables() : seq[string] =
  ## Calculates which Python executables to use for testing
  ## The default is to use "python2" and "python3"
  ##
  ## You can override this by setting the environment
  ## variable `NIMPY_PY_EXES` to a comma separated list
  ## of Python executables to invoke. For example, to test
  ## with Python 2 from the system PATH and multiple versions
  ## of Python 3, you might invoke something like
  ##
  ## `NIMPY_PY_EXES="python2:/usr/local/bin/python3.7:/usr/local/bin/python3.8" nimble test`
  ##
  ## These are launched via a shell so they can be scripts
  ## as well as actual Python executables

  let pyExes = getEnv("NIMPY_PY_EXES", "python2:python3")
  result = pyExes.split(":")

proc calcLibPythons() : seq[string] =
  ## Calculates which libpython modules to use for testing
  ## The default is to use whichever libpython is found
  ## by `pythonLibHandleFromExternalLib()` in py_lib.nim
  ##
  ## You can override this by setting the environment
  ## variable `NIMPY_LIBPYTHONS` to a comma separated list
  ## of libpython modules to load. For example, you might 
  ## invoke something like
  ##
  ## `NIMPY_LIBPYTHONS="/usr/lib/x86_64-linux-gnu/libpython2.7.so:/usr/lib/x86_64-linux-gnu/libpython3.8.so" nimble test`
  ##
  let libPythons = getEnv("NIMPY_LIBPYTHONS", "")
  result = libPythons.split(":")

proc runTests(nimFlags = "") =
  let pluginExtension = when defined(windows): "pyd" else: "so"

  for f in oswalkdir.walkDir("tests"):
    # Compile all nim modules, except those starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".nim" and not sf.name.startsWith("t"):
      exec "nim c --threads:on --app:lib " & nimFlags & " --out:" & f.path.changeFileExt(pluginExtension) & " " & f.path

  let
    sourceFile = "tests/custommodulename".changeFileExt(pluginExtension)
    targetFile = "tests/_mycustommodulename".changeFileExt(pluginExtension)
  try:
    rmFile(targetFile)
  except:
    discard
  mvFile(sourceFile, targetFile)

  let
    pythonExes = calcPythonExecutables()
    libPythons = calcLibPythons()

  for f in oswalkdir.walkDir("tests"):
    # Run all python modules starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".py" and sf.name.startsWith("t"):
      for pythonExe in pythonExes:
        echo "Testing Python executable: ", pythonExe
        exec pythonExe & " " & f.path

  for f in oswalkdir.walkDir("tests"):
    # Run all nim modules starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".nim" and sf.name.startsWith("t"):
      for libPython in libPythons:
        exec "nim c -d:nimpyTestLibPython=" & libPython & " -r " & nimFlags & " " & f.path

task test, "Run tests":
  runTests()
  runTests("--gc:arc --passc:-g") # Arc

task test_arc, "Run tests with --gc:arc":
  runTests("--gc:arc --passc:-g")
