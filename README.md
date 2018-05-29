# nimpy [![Build Status](https://travis-ci.org/yglukhov/nimpy.svg?branch=master)](https://travis-ci.org/yglukhov/nimpy)

Native language integration with Python has never been easier!

## Implementing python module in nim
```nim
# mymodule.nim
import nimpy

proc greet(name: string): string {.exportpy.} =
    return "Hello, " & name & "!"
```

```
# Compile on Windows:
nim c --app:lib --out:mymodule.pyd mymodule
# Compile on everything else:
nim c --app:lib --out:mymodule.so mymodule
```

```py
# test.py
import mymodule
assert(mymodule.greet("world") == "Hello, world!")
```

## Calling python from nim
```nim
import nimpy
let os = pyImport("os")
echo "Current dir is: ", os.getcwd().to(string)

# sum(xrange(1, 5))
let py = pyBuiltinsModule()
let s = py.sum(py.xrange(0, 5)).to(int)
assert(s == 10)
```

## Misc
The library is designed with ABI compatibility in mind. That is
the compiled module doesn't depend on particular Python version, it should
properly work with any. The C API symbols are loaded in runtime from whichever
process has launched your module.

## Future directions
* exporting Nim types/functions as Python classes/methods
