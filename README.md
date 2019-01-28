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
Note: here nimpy relies on your local python installation.

## Misc
The library is designed with ABI compatibility in mind. That is
the compiled module doesn't depend on particular Python version, it should
properly work with any. The C API symbols are loaded in runtime from whichever
process has launched your module.


## Troubleshooting, Q&A
<details>
<summary> <b>Question:</b>

Importing the compiled module from Python fails with `ImportError: dynamic module does not define module export function ...`
</summary>

  Make sure that the module you're importing from Python has exactly the same name as the `nim` file which the module is implemented in.
</details>

<details>
<summary> <b>Question:</b>

Nim strings are converted to Python `bytes` instead of `string`
</summary>

  nimpy converts Nim strings to Python strings usually, but since Nim strings are encoding agnostic and may contain invalid utf8 sequences, nimpy will fallback to Python `bytes` in such cases.
</details>

<details>
<summary> <b>Question:</b>

Is there any numpy compatibility?
</summary>

  nimpy allows manipulating numpy objects just how you would do it in Python,
however it not much more efficient. To get the maximum performance nimpy
exposes [Buffer protocol](https://docs.python.org/3/c-api/buffer.html), see
[raw_buffers.nim](https://github.com/yglukhov/nimpy/blob/master/nimpy/raw_buffers.nim).
[tpyfromnim.nim](https://github.com/yglukhov/nimpy/blob/master/tests/tpyfromnim.nim)
contains a very basic test for this (grep `numpy`). Higher level API might
be considered in the future, PRs are welcome.
</details>

<details>
<summary> <b>Question:</b>

Does nim default garbage collector (GC) work?
</summary>

  nimpy internally does everything needed to run the GC properly (keeps the stack bottom
  actual, and appropriate nim references alive), and doesn't introduce any special rules
  on top. So the GC question boils down to proper GC usage in nim shared libraries,
  you'd better lookup elsewhere. The following guidelines are by no means comprehensive,
  but should be enough for the quick start:
  - If it's known there will be only one nimpy module in the process, you should be fine.
  - If there is more than one nimpy module, it is recommended to [move nim runtime out
    to a separate shared library](https://nim-lang.org/docs/nimc.html#dll-generation).
    However it might not be needed if nim references are known to never travel between
    nim shared libraries.
  - If you hit any GC problems with nimpy, whether you followed these guidelines or not,
    please report them to nimpy tracker :)

</details>

## Future directions
* exporting Nim types/functions as Python classes/methods
* High level buffer API

