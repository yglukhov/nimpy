# python [![Build Status](https://travis-ci.org/yglukhov/python.svg?branch=master)](https://travis-ci.org/yglukhov/python)

Native language integration with Python has never been easier!

```nim
# mymodule.nim
import python

proc greet(name: string): string {.exportpy.} =
    return "Hello, " & name & "!"
```

```
# Compile:
nim c --threads:on --tlsEmulation:off --app:lib --out:mymodule.so mymodule
```

```py
# test.py
import mymodule
assert(mymodule.greet("world") == "Hello, world!")
```

# Misc
This is a very much work in progress, but already may prove useful for some
simple cases.

The library is designed with ABI compatibility in mind. That is
the compiled module doesn't depend on particular Python version, it should
properly work with any. The C API symbols are loaded in runtime from whichever
process has launched your module.

Eventually the lib should support:
* exporting Nim types/functions as Python classes/methods
* using Python types and functions from within Nim
* starting Python environment in cases when its not already started. In other words - embedding Python into your program
