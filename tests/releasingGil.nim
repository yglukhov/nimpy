# Access Python Objects concurentally without using the Python Global Interpreter Lock (GIL)

# Load necessary Python C API functions

#[
  author: Casper van Elteren
  To improve preformance of Nim code that uses Python objects, you can release the Python Global Interpreter Lock (GIL) while executing Nim code. The GIL is a necessary evin in cPython to prevent racing conditions. However, it can be a bottleneck in multi-threaded applications. This example demonstrates how to release the GIL in Nim code and access Python objects concurrently.

  This examples examples how to interface with python objects from different threads without in a way such that the GIL is not held. This can lead to great performance in nim when interactinos with python objects is in and far between, and on a critical execution path.

  The c-api for python exposes several functions to ensure that a process holds the GIL. These functions feel foreign from a python perspective, but all they do is ensure that the GIL is properly dealth with such that any creation, modification of deletion of python objects is correctly counted.
]#
import nimpy, nimpy/py_lib
import dynlib

# Generally we just use one interpreter, although multiple could be used. So we define a new type-safe int to represent our GIL
type
  PyGILState_STATE* = distinct int
  PyThreadState* = pointer

#[
  Nimpy exposes the python python library to an internally held module. These modules in principles could be spawned such that we have seperate python processees. This is not the case here, but it is a possibility. The module is used to access the python c-api functions that are specific to that process.
]#
initPyLibIfNeeded() # initialize the python module in Nimpy
let py = py_lib.pyLib.module

let
  PyGILState_Ensure =
    cast[proc(): PyGILState_STATE {.cdecl, gcsafe.}](py.symAddr("PyGILState_Ensure"))
    # Ensures that we have the GIL
  PyGILState_Release = cast[proc(state: PyGILState_STATE) {.cdecl, gcsafe.}](py.symAddr(
    "PyGILState_Release"
  )) # Releases the GIL
  # The following functions do the same as above, but are more low-level and are "intended" for when the gil is released for longer periods of time
  PyEval_SaveThread =
    cast[proc(): PyThreadState {.cdecl.}](py.symAddr("PyEval_SaveThread"))
  PyEval_RestoreThread =
    cast[proc(tstate: PyThreadState) {.cdecl.}](py.symAddr("PyEval_RestoreThread"))

# This represents the "python" process
var mainThreadState: PyThreadState

proc initPyThread*() =
  # This should be called once at the start of your program
  mainThreadState = PyEval_SaveThread()

# A way to template your code, and uses a similar structure as the withGIL macro in cython
template withPyGIL*(code: untyped) =
  let state = PyGILState_Ensure()
  try:
    code
  finally:
    PyGILState_Release(state)

# Generally used to run "longer" stuff in nim
proc withoutPyGIL*(body: proc()) =
  let threadState = PyEval_SaveThread()
  try:
    body()
  finally:
    PyEval_RestoreThread(threadState)

# Example usage
proc pyThreadSafeFunction() {.gcsafe.} =
  #[
    We are explicitly creating a python object on every function call (nx, g) then we modify the objects. If we would have used a global variable for nx, the GIL should be held as potential modifications would be subject to racing conditions.
  ]#
  withPyGIL:
    let nx = pyImport("networkx")
    let g = nx.path_graph(3)
    g.nodes()[0]["example_trait"] = "example_value"

# Initialize Python threading
initPyThread()

# Use in your code
# We are using malebolgia here, but the principle holds for other threading libraries
import malebolgia
var m = malebolgia.createMaster()
m.awaitAll:
  for idx in (0 .. 10000):
    m.spawn:
      pyThreadSafeFunction()
pyThreadSafeFunction()
