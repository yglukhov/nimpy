import nimpy
import nimpy/py_types
import nimpy/py_lib as lib
import strformat

type
    PyCustomType* = ref object of PyNimObjectExperimental
        a* : int
        b* : float
        c* : string

proc initPyCustomType*(self : PyCustomType, aa: int = 1, bb: float = 2.0, cc: string = "default") {.exportpy} =
    echo "Calling initPyCustomType for PyCustomType"
    self.a = aa
    self.b = bb
    self.c = cc

proc destroyPyCustomType*(self : PyCustomType) {.exportpy} =
    echo "Calling destroyPyCustomType for PyCustomType"

proc `$`*(self : PyCustomType) : string {.exportpy} =
    echo "Calling $ for PyCustomType"
    result = "a: " & $self.a & ", b: " & $self.b & ", c: " & self.c

proc get_a*(self : PyCustomType) : int {.exportpy} =
    echo "Calling get_a for PyCustomType inside nim"
    return self.a

proc set_a*(self : PyCustomType, val : int) {.exportpy} =
    echo "Calling set_a for PyCustomType inside nim"
    self.a = val

setModuleDocString("This is a test module")
setDocStringForType(PyCustomType, "This is a test type")

import unittest
import math

suite "Test Exporting NimObject as Python Type with __init__, __del__, __repr__, __doc__":
    let m = pyImport("texport_pytype")
    
    test "Test __doc__":
        check getAttr(m, "__doc__").`$` == "This is a test module"
        check getAttr(getAttr(m, "PyCustomType"), "__doc__").`$` == "This is a test type"
    
    test "Test __init__":
        let constructor = getAttr(m, "PyCustomType")
        let obj = callObject(constructor, 99, 3.14, "hello")
        check obj.get_a().to(int) == 99
    
    test "Test __del__":
        let constructor = getAttr(m, "PyCustomType")
        let obj = callObject(constructor, 99, 3.14, "hello")
        let destructor = getAttr(obj, "__del__")
        discard callObject(destructor)
    
    test "Test __repr__":
        let constructor = getAttr(m, "PyCustomType")
        let obj = callObject(constructor, 99, 3.14, "hello")
        check obj.`$` == "a: 99, b: 3.14, c: hello"