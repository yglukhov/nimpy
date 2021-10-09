# Tests for PyRun_xxx stuff

import ../nimpy

proc test_pyrun_string*() {.gcsafe.} =
  
  block:    # simple test
    let pyCode = "print('Hello')" 
    let pyResult =  pyRun_SimpleString(pyCode)
    doAssert(pyResult == 0)

  block:
    let pyCode = "invalid python. Shouldn't compile"
    let pyResult =  pyRun_SimpleString(pyCode)
    doAssert(pyResult == -1)

  block:    # multi-line input. Also sets global for next test
    let pyCode = """
import math
x = math.pow(2, 3)
    """
    let pyResult =  pyRun_SimpleString(pyCode)
    doAssert(pyResult == 0)

  block:
    let pyCode = """
if x != 8:
  raise ValueError("Expected variable 'x' to be set from previous test")
    """
    let pyResult =  pyRun_SimpleString(pyCode)
    doAssert(pyResult == 0)

proc test_pyrun_file*() {.gcsafe.} =
  
  block:
    let fileName = "tests/pyrunfile.py"
    let pyResult =  pyRun_SimpleFile(fileName)
    doAssert(pyResult == 0)

  block:
    doAssertRaises(IOError):
      let fileName = "does_not_exist.py"
      discard  pyRun_SimpleFile(fileName)

when isMainModule:
  test_pyrun_string()
  test_pyrun_file()
  echo "Test complete!"
