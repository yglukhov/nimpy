# Using nimpy in micropython

[MicroPython](https://micropython.org) is a lean and efficient implementation
of the Python 3 programming language that includes a small subset of the Python
standard library and is optimised to run on microcontrollers and in constrained
environments. 

The following steps describe the process of extending micropython with custom
modules in Nim.

## Definitions
* `MP_DIR` - Path to directory, where micropython is installed.
* `MP_PORT` - Path to the specific micropython port in use. E.g. `MP_DIR/ports/stm32`, `MP_DIR/ports/unix`, etc.
* `NIMPY_DIR` - Path to the locally checked out copy of this repo.

## Adding nim code to micropython port
1. Copy `NIMPY_DIR/micropython/nim` directory to `MP_PORT/nim`
2. Find the `SRC_C = ...` line in `MP_PORT/Makefile` and add `include nim/nim.mk` immediately before this line, e.g.:
```
...
include nim/nim.mk
SRC_C = \
        main.c \
        system_stm32.c \
        stm32_it.c \
        ...
```
3. See `MP_PORT/nim/mymodule.nim` for an example.
4. Run `make` in the `MP_PORT` directory to rebuild the port.

