# nimpy [![CI](https://github.com/yglukhov/nimpy/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/yglukhov/nimpy/actions/workflows/test.yml) [![nimble](https://img.shields.io/badge/nimble-black?logo=nim&style=flat&labelColor=171921&color=%23f3d400)](https://nimble.directory/pkg/nimpy)

Native language integration with Python has never been easier!

## Implementing a Python Module in Nim
```nim
# mymodule.nim - file name should match the module name you're going to import from python
import nimpy

proc greet(name: string): string {.exportpy.} =
  return "Hello, " & name & "!"
```

```bash
# Compile on Windows:
nim c --app:lib --out:mymodule.pyd --threads:on --tlsEmulation:off --passL:-static mymodule
# Compile on everything else:
nim c --app:lib --out:mymodule.so --threads:on mymodule
```

```py
# test.py
import mymodule
assert mymodule.greet("world") == "Hello, world!"
assert mymodule.greet(name="world") == "Hello, world!"
```

## Calling Python From Nim
```nim
import nimpy
let os = pyImport("os")
echo "Current dir is: ", os.getcwd().to(string)

# sum(range(1, 5))
let py = pyBuiltinsModule()
let s = py.sum(py.range(0, 5)).to(int)
assert s == 10
```
Note: here nimpy relies on your local python installation.


## Importing Nim Extensions Directly

For a convenient way to import your Nim extension modules directly, you can use
[Nimporter](https://github.com/Pebaz/Nimporter).


## Misc
The library is designed with ABI compatibility in mind. That is
the compiled module doesn't depend on particular Python version, it should
properly work with any. The C API symbols are loaded in runtime from whichever
process has launched your module.


## Troubleshooting, Q&A
<details>
<summary> <b>Importing the compiled module from Python fails</b> </summary>

  If you're getting `ImportError: dynamic module does not define module export function ...`
  make sure that the module you're importing from Python has exactly the same name as the `nim` file which the module is implemented in.
</details>

<details>
<summary> <b>Nimpy fails to find (proper) libpython</b> </summary>

  The most reliable way to find libpython is `find_libpython` python package:
  ```
  pip3 install find_libpython
  python3 -c 'import find_libpython; print(find_libpython.find_libpython())'
  ```
  Then you can specify path to libpython using `nimpy.py_lib.pyInitLibPath`. Tracking issue: #171.
</details>

<details>
<summary> <b>Nim strings are converted to Python bytes instead of string</b> </summary>

  nimpy converts Nim strings to Python strings usually, but since Nim strings are encoding agnostic and may contain invalid utf8 sequences, nimpy will fallback to Python `bytes` in such cases.
</details>

<details>
<summary> <b>Is there any numpy compatibility?</b> </summary>

  nimpy allows manipulating numpy objects just how you would do it in Python,
however it is not much more efficient. [scinim](https://github.com/SciNim/scinim) offers
API for performance critical numpy interop, and it is advised to consider it first.

Nimpy also exposes lower level [Buffer protocol](https://docs.python.org/3/c-api/buffer.html),
see [raw_buffers.nim](https://github.com/yglukhov/nimpy/blob/master/nimpy/raw_buffers.nim).
[tpyfromnim.nim](https://github.com/yglukhov/nimpy/blob/master/tests/numpytest.nim)
contains a very basic test for this.
</details>

<details>
<summary> <b>Does nim default garbage collector (GC) and ARC/ORC work?</b> </summary>

  Yes. nimpy internally does everything needed to run the GC properly (keeps the stack bottom
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

<details>
<summary> <b>Windows, threads and MinGW</b> </summary>

  When compiling with `--threads:on` Nim will imply `--tlsEmulation:on` (Windows only) which
  prevents Nim runtime from initing properly when being called from a foreign thread (which is
  always the case in case of Python module).

  Adding `--tlsEmulation:off` when using MinGW toolchain (Nim's default on Windows) will
  introduce a dependency on `libgcc_s_seh-*.dll`, that newer python versions are often unable
  to find.

  One way to overcome this is to link with libgcc statically, by passing `-static` to linker,
  or `--passL:-static` to Nim.

</details>

## Exporting Nim types as Python classes
Warning! This is experimental.
* An exported type should be a ref object and inherit `PyNimObjectExperimental` directly or indirectly.
* The type will only be exported if at least one exported "method" is defined.
* A proc will be exported as python type method *only* if it's first argument is of the corresponding type and is called `self`. If the first argument is not called `self`, the proc will exported as a global module function.
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


## Future directions
* High level buffer API

## Stargazers over time

[![Stargazers over time](https://starchart.cc/yglukhov/nimpy.svg)](https://starchart.cc/yglukhov/nimpy)
