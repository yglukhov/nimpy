# nimpy [![Build Status](https://travis-ci.org/yglukhov/nimpy.svg?branch=master)](https://travis-ci.org/yglukhov/nimpy)

Native language integration with Python has never been easier!

## Implementing python module in nim
```nim
# mymodule.nim - file name should match the module name you're going to import from python
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

# sum(range(1, 5))
let py = pyBuiltinsModule()
let s = py.sum(py.range(0, 5)).to(int)
assert(s == 10)
```

## Misc
The library is designed with ABI compatibility in mind. That is
the compiled module doesn't depend on particular Python version, it should
properly work with any. The C API symbols are loaded in runtime from whichever
process has launched your module.

## Troubleshooting
- Importing the compiled module from Python fails with `ImportError: dynamic module does not define module export function ...`

  Make sure that the module you're importing from Python has exactly the same name as the `nim` file which the module is implemented in.


## Future directions
* exporting Nim types/functions as Python classes/methods
