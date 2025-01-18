## Exporting Nim types as Python classes

Warning! This is experimental.
* An exported type should be a ref object and inherits `PyNimObjectExperimental` directly or indirectly.
* The type will only be exported if at least one exported "method" is defined.
* A proc will be exported as python type method *only* if it's first argument is of the corresponding type and is called `self`. If the first argument is not called `self`, the proc will exported as a global module function.

#### Simple Example
```nim
# mymodule.nim
type TestType = ref object of PyNimObjectExperimental
  myField: string

proc setMyField(self: TestType, value: string) {.exportpy.} =
  self.myField = value

proc getMyField(self: TestType): string {.exportpy.} =
  self.myField
```

``` py
# test.py
import mymodule
tt = mymodule.TestType()
tt.setMyField("Hello")
assert(tt.getMyField() == "Hello")
```

#### `__init__`, `__del__`, and `__repr__`
* [example](../tests/export_pytype.nim)
```nim
# simple.nim
## compile as simple.so

import nimpy
import strformat

pyExportModule("simple") # only needed if your filename is not simple.nim

type
    SimpleObj* = ref object of PyNimObjectExperimental
        a* : int

## if 
##    1) the function name is like `init##TypeName`
##    2) there is only one argument
##    3) the first argument name is "self"
##    4) the first argument type is `##TypeName`
##    5) there is no return type
## we export this function as a python object method __init__ (tp_init in PyTypeObject)
proc initSimpleObj*(self : SimpleObj, a : int = 1) {.exportpy} =
    echo "Calling initSimpleObj for SimpleObj"
    self.a = a

## if 
##    1) the function name is like `destroy##TypeName`
##    2) there is only one argument
##    3) the first argument name is "self"
##    4) the first argument type is `##TypeName`
##    5) there is no return type
## we export this function as a python object method __del__ (tp_finalize in PyTypeObject)
## !! Warning, this is only available since Python3.4, for older versions, the destroySimpleObj
## below will be ignore.
proc destroySimpleObj*(self : SimpleObj) {.exportpy.} =
    echo "Calling destroySimpleObj for SimpleObj"

## if
##    1) the function name is like `$`
##    2) there is only one argument
##    3) the first argument name is "self"
##    4) the first argument type is `##TypeName`
##    5) the return type is `string`
## we export this function as a python object method __repr__ (tp_repr in PyTypeObject)
proc `$`*(self : SimpleObj): string {.exportpy.} =
   &"SimpleObj : a={self.a}" 


## Change doc string
setModuleDocString("This is a test module")
setDocStringForType(SimpleObj, "This is a test type")
```

* Compile as `simple.so`
```bash
nim c --app:lib -o:./simple.so ./simple.nim
```

* Use the exported python type in python
```python
import simple
print(simple.__doc__)
print(simple.SimpleObj.__doc__)
obj = simple.SimpleObj(a = 2)
print(obj)
obj.__del__()
```