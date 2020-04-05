import ../nimpy
import os
import modules/other_module

proc greet_from_exe(name: string): string {.exportpy.} =
  ## This is the docstring
  return "Hello, " & name & "!"

# Make sure Python can find builtinpyfromnim.py
let sys = pyImport("sys")
discard sys.path.append(currentSourcePath.parentDir)

let pytest {.used.} = pyImport("builtinpyfromnim")
assert(pytest.x.to(int) == 42)
