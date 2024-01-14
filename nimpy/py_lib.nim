import dynlib, sequtils, strutils, complex, py_types

{.pragma: pyfunc, cdecl, gcsafe.}

type
  PyLib* = ptr object
    module*: LibHandle

    Py_BuildValue*: proc(f: cstring): PPyObject {.pyfunc, varargs.}
    PyTuple_New*: proc(sz: Py_ssize_t): PPyObject {.pyfunc.}
    PyTuple_Size*: proc(f: PPyObject): Py_ssize_t {.pyfunc.}
    PyTuple_GetItem*: proc(f: PPyObject, i: Py_ssize_t): PPyObject {.pyfunc.}
    PyTuple_SetItem*: proc(f: PPyObject, i: Py_ssize_t, v: PPyObject): cint {.pyfunc.}

    Py_None*: PPyObject
    PyType_Ready*: proc(f: PyTypeObject): cint {.pyfunc.}
    PyType_GenericNew*: proc(f: PyTypeObject, a, b: PPyObject): PPyObject {.pyfunc.}
    PyModule_AddObject*: proc(m: PPyObject, n: cstring, o: PPyObject): cint {.pyfunc.}

    # PyList_Check*: proc(l: PPyObject): cint {.pyfunc.}
    PyList_New*: proc(size: Py_ssize_t): PPyObject {.pyfunc.}
    PyList_Size*: proc(l: PPyObject): Py_ssize_t {.pyfunc.}
    PyList_GetItem*: proc(l: PPyObject, index: Py_ssize_t): PPyObject {.pyfunc.}
    PyList_SetItem*: proc(l: PPyObject, index: Py_ssize_t, i: PPyObject): cint {.pyfunc.}

    PyObject_Call*: proc(callable_object, args, kw: PPyObject): PPyObject {.pyfunc.}
    PyObject_IsTrue*: proc(o: PPyObject): cint {.pyfunc.}
    # PyObject_HasAttrString*: proc(o: PPyObject, name: cstring): cint {.pyfunc.}
    PyObject_GetAttrString*: proc(o: PPyObject, name: cstring): PPyObject {.pyfunc.}
    PyObject_SetAttrString*: proc(o: PPyObject, name: cstring, v: PPyObject): cint {.pyfunc.}
    PyObject_Dir*: proc(o: PPyObject): PPyObject {.pyfunc.}
    PyObject_Str*: proc(o: PPyObject): PPyObject {.pyfunc.}
    PyObject_GetIter*: proc(o: PPyObject): PPyObject {.pyfunc.}
    PyObject_GetItem*: proc(o, k: PPyObject): PPyObject {.pyfunc.}
    PyObject_SetItem*: proc(o, k, v: PPyObject): cint {.pyfunc.}
    PyObject_RichCompareBool*: proc(a, b: PPyObject, op: cint): cint {.pyfunc.}
    PyObject_GetBuffer*: proc(o: PPyObject, b: var RawPyBuffer, flags: cint): cint {.pyfunc.}
    PyBuffer_Release*: proc(b: var RawPyBuffer) {.pyfunc.}

    PyErr_NewException*: proc(name: cstring, base: PPyObject, dict: PPyObject): PPyObject {.pyfunc.}

    PyIter_Next*: proc(o: PPyObject): PPyObject {.pyfunc.}

    PyNumber_Long*: proc(l: PPyObject): PPyObject {.pyfunc.}
    PyLong_AsLongLong*: proc(l: PPyObject): int64 {.pyfunc.}
    PyLong_AsUnsignedLongLong*: proc(l: PPyObject): uint64 {.pyfunc.}
    PyFloat_AsDouble*: proc(l: PPyObject): cdouble {.pyfunc.}
    PyBool_FromLong*: proc(v: clong): PPyObject {.pyfunc.}

    PyBool_Type*: PyTypeObject
    PyFloat_Type*: PyTypeObject
    PyComplex_Type*: PyTypeObject
    PyCapsule_Type*: PyTypeObject
    PyTuple_Type*: PyTypeObject
    PyList_Type*: PyTypeObject
    PyBytes_Type*: PyTypeObject
    PyUnicode_Type*: PyTypeObject
    PySuper_Type*: PyTypeObject

    PyType_IsSubtype*: proc(t1, t2: PyTypeObject): cint {.pyfunc.}

    when declared(Complex64):
      PyComplex_AsCComplex*: proc(op: PPyObject): Complex64 {.pyfunc.}
    else:
      PyComplex_AsCComplex*: proc(op: PPyObject): Complex {.pyfunc.}

    PyComplex_RealAsDouble*: proc(op: PPyObject): cdouble {.pyfunc.}
    PyComplex_ImagAsDouble*: proc(op: PPyObject): cdouble {.pyfunc.}

    PyUnicode_AsUTF8String*: proc(o: PPyObject): PPyObject {.pyfunc.}
    PyBytes_FromStringAndSize*: proc(s: ptr char, len: Py_ssize_t): PPyObject {.pyfunc.}
    PyBytes_AsStringAndSize*: proc(o: PPyObject, s: ptr ptr char, len: ptr Py_ssize_t): cint {.pyfunc.}
    PyUnicode_FromString*: proc(s: cstring): PPyObject {.pyfunc.}
    PyUnicode_CompareWithASCIIString*: proc(o: PPyObject, s: cstring): cint {.pyfunc.}
    PyString_AsString*: proc(o: PPyObject): cstring {.pyfunc.}

    PyDict_Type*: PyTypeObject
    PyDict_New*: proc(): PPyObject {.pyfunc.}
    PyDict_Size*: proc(d: PPyObject): Py_ssize_t {.pyfunc.}
    PyDict_GetItemString*: proc(o: PPyObject, k: cstring): PPyObject {.pyfunc.}
    PyDict_SetItemString*: proc(o: PPyObject, k: cstring, v: PPyObject): cint {.pyfunc.}
    PyDict_GetItem*: proc(o: PPyObject, k: PPyObject): PPyObject {.pyfunc.}
    PyDict_SetItem*: proc(o: PPyObject, k, v: PPyObject): cint {.pyfunc.}
    PyDict_Keys*: proc(o: PPyObject): PPyObject {.pyfunc.}
    PyDict_Values*: proc(o: PPyObject): PPyObject {.pyfunc.}
    PyDict_Contains*: proc(o: PPyObject, k: PPyObject): cint {.pyfunc.}

    PyDealloc*: proc(o: PPyObject) {.nimcall, gcsafe.}

    PyErr_Clear*: proc() {.pyfunc.}
    PyErr_SetString*: proc(o: PPyObject, s: cstring) {.pyfunc.}
    PyErr_Occurred*: proc(): PPyObject {.pyfunc.}
    PyExc_TypeError*: PPyObject

    PyCapsule_New*: proc(p: pointer, name: cstring, destr: proc(o: PPyObject) {.pyfunc.}): PPyObject {.pyfunc.}
    PyCapsule_GetPointer*: proc(c: PPyObject, name: cstring): pointer {.pyfunc.}

    PyImport_ImportModule*: proc(name: cstring): PPyObject {.pyfunc.}
    PyEval_GetBuiltins*: proc(): PPyObject {.pyfunc.}
    PyEval_GetGlobals*: proc(): PPyObject {.pyfunc.}
    PyEval_GetLocals*: proc(): PPyObject {.pyfunc.}

    PyCFunction_NewEx*: proc(md: ptr PyMethodDef, self, module: PPyObject): PPyObject {.pyfunc.}

    pythonVersion*: tuple[major, minor, micro: int]

    when not defined(release):
      PyErr_Print*: proc() {.pyfunc.}
    PyErr_Fetch*: proc(ptype, pvalue, ptraceback: ptr PPyObject) {.pyfunc.}
    PyErr_NormalizeException*: proc(ptype, pvalue, ptraceback: ptr PPyObject) {.pyfunc.}

    PyErr_GivenExceptionMatches*: proc(given, exc: PPyObject): cint {.pyfunc.}

    PyExc_BaseException*: PPyObject # should always match any exception?
    PyExc_Exception*: PPyObject
    PyExc_ArithmeticError*: PPyObject
    PyExc_AssertionError*: PPyObject
    PyExc_AttributeError*: PPyObject
    # PyExc_BlockingIOError # no
    # PyExc_BrokenPipeError
    # PyExc_BufferError
    # PyExc_ChildProcessError
    # PyExc_ConnectionAbortedError
    # PyExc_ConnectionError
    # PyExc_ConnectionRefusedError
    # PyExc_ConnectionResetError
    PyExc_EOFError*: PPyObject
    # PyExc_FileExistsError
    # PyExc_FileNotFoundError
    PyExc_FloatingPointError*: PPyObject
    # PyExc_GeneratorExit
    # PyExc_ImportError
    # PyExc_IndentationError # no
    PyExc_IndexError*: PPyObject
    # PyExc_InterruptedError
    PyExc_IOError*: PPyObject # in Python 3 IOError *is* OSError
    # PyExc_IsADirectoryError
    PyExc_KeyError*: PPyObject
    # PyExc_KeyboardInterrupt
    # PyExc_LookupError
    PyExc_MemoryError*: PPyObject
    # PyExc_ModuleNotFoundError
    # PyExc_NameError
    # PyExc_NotADirectoryError
    # PyExc_NotImplementedError
    PyExc_OSError*: PPyObject
    PyExc_OverflowError*: PPyObject
    # PyExc_PermissionError
    # PyExc_ProcessLookupError
    # PyExc_RecursionError
    # PyExc_ReferenceError
    # PyExc_RuntimeError
    # PyExc_StopAsyncIteration
    # PyExc_StopIteration
    # PyExc_SyntaxError
    # PyExc_SystemError
    # PyExc_SystemExit
    # PyExc_TabError
    # PyExc_TimeoutError
    # PyExc_TypeError
    # PyExc_UnboundLocalError
    # PyExc_UnicodeDecodeError
    # PyExc_UnicodeEncodeError
    # PyExc_UnicodeError
    # PyExc_UnicodeTranslateError
    PyExc_ValueError*: PPyObject
    PyExc_ZeroDivisionError*: PPyObject

    NimPyException*: PPyObject


var pyObjectStartOffset*: uint
var pyLib*: PyLib
var pyThreadFrameInited {.threadvar.}: bool

type
  ExportedModule = object
    name : string
    initAddr2 : pointer
    initAddr3 : pointer

var exportedModules : seq[ExportedModule] = @[]

proc registerExportedModule*(name: string, initAddr2, initAddr3 : pointer) =  # Registers a module name and its init function pointers
  exportedModules.add(
    ExportedModule(
      name: name,
      initAddr2: initAddr2,
      initAddr3: initAddr3
    )
  )

proc to*(p: PPyObject, t: typedesc): ptr t {.inline.} =
  result = cast[ptr t](cast[uint](p) + pyObjectStartOffset)

proc deallocPythonObj[TypeObjectType](p: PPyObject) {.gcsafe.} =
  let ob = p.to(PyObjectObj)
  let t = cast[TypeObjectType](ob.ob_type)
  t.tp_dealloc(cast[PPyObject](p))

proc symNotLoadedErr(s: cstring) =
  raise newException(ValueError, "Symbol not loaded: " & $s)

proc getPyVersion(pyLibHandle: LibHandle): tuple[major, minor, micro: int] =
  # Py_GetVersion is documented to be OK to call before
  # Py_Initialize so we can use it for determining which
  # init function to supply to PyImport_AppendInittab
  # (although there seems to be at least one Python distro
  #  that may have issues with this, so maybe a different
  #  approach is warranted?
  #  See https://modwsgi.readthedocs.io/en/develop/release-notes/version-4.5.7.html
  #  and https://twitter.com/grahamdumpleton/status/773383080002269184 )
  let pyVersionFuncPtr = cast[proc() : cstring {.pyfunc.}](pyLibHandle.symAddr("Py_GetVersion"))
  if pyVersionFuncPtr.isNil:
    raise newException(ValueError, "Could not determine Python version")

  let pyVersion = pyVersionFuncPtr()
  proc c_sscanf(str, fmt: cstring): cint {.varargs, importc: "sscanf", header: "<stdio.h>".}

  var major, minor, micro: cint
  if unlikely c_sscanf(pyVersion, "%d.%d.%d", addr major, addr minor, addr micro) <= 0:
    raise newException(ValueError, "Could not determine Python version: " & $pyVersion)
  (major.int, minor.int, micro.int)

proc loadPyLibFromModule(m: LibHandle): PyLib =
  assert(not m.isNil)
  result = cast[PyLib](allocShared0(sizeof(result[])))
  let pl = result
  pl.module = m
  pl.pythonVersion = getPyVersion(m)

  if not (m.symAddr("PyModule_Create2").isNil or
      m.symAddr("Py_InitModule4_64").isNil or
      m.symAddr("Py_InitModule4").isNil):
    # traceRefs mode
    pyObjectStartOffset = sizeof(PyObject_HEAD_EXTRA).uint

  template maybeLoad(v: untyped, name: cstring) =
    pl.v = cast[type(pl.v)](m.symAddr(name))

  template load(v: untyped, name: cstring) =
    maybeLoad(v, name)
    if pl.v.isNil:
      symNotLoadedErr(name)

  template maybeLoad(v: untyped) = maybeLoad(v, astToStr(v))
  template load(v: untyped) = load(v, astToStr(v))

  template loadVar(v: untyped) =
    load(v)
    pl.v = cast[ptr PPyObject](pl.v)[]

  load Py_BuildValue, "_Py_BuildValue_SizeT"
  load PyTuple_New
  load PyTuple_Size
  load PyTuple_GetItem
  load PyTuple_SetItem

  load Py_None, "_Py_NoneStruct"
  load PyType_Ready
  load PyType_GenericNew
  load PyModule_AddObject

  load PyList_New
  load PyList_Size
  load PyList_GetItem
  load PyList_SetItem

  load PyObject_Call
  load PyObject_IsTrue
  # load PyObject_HasAttrString
  load PyObject_GetAttrString
  load PyObject_SetAttrString
  load PyObject_Dir
  load PyObject_Str
  load PyObject_GetIter
  load PyObject_GetItem
  load PyObject_SetItem
  load PyObject_RichCompareBool

  maybeLoad PyObject_GetBuffer
  maybeLoad PyBuffer_Release

  load PyIter_Next

  load PyNumber_Long
  load PyLong_AsLongLong
  load PyLong_AsUnsignedLongLong
  load PyFloat_AsDouble
  load PyBool_FromLong

  load PyBool_Type
  load PyFloat_Type
  load PyComplex_Type
  load PyCapsule_Type
  load PyTuple_Type
  load PyList_Type
  load PyUnicode_Type
  load PySuper_Type
  maybeLoad PyBytes_Type
  if pl.PyBytes_Type.isNil:
    # Needed for compatibility with Python 2
    load PyBytes_Type, "PyString_Type"


  maybeLoad PyUnicode_FromString
  if pl.PyUnicode_FromString.isNil:
    load PyUnicode_FromString, "PyString_FromString"

  load PyType_IsSubtype

  maybeLoad PyComplex_AsCComplex
  if pl.PyComplex_AsCComplex.isNil:
    load PyComplex_RealAsDouble
    load PyComplex_ImagAsDouble

  maybeLoad PyUnicode_CompareWithASCIIString
  if pl.PyUnicode_CompareWithASCIIString.isNil:
    load PyString_AsString

  maybeLoad PyUnicode_AsUTF8String
  if pl.PyUnicode_AsUTF8String.isNil:
    maybeLoad PyUnicode_AsUTF8String, "PyUnicodeUCS4_AsUTF8String"
    if pl.PyUnicode_AsUTF8String.isNil:
      load PyUnicode_AsUTF8String, "PyUnicodeUCS2_AsUTF8String"

  maybeLoad PyBytes_AsStringAndSize
  maybeLoad PyBytes_FromStringAndSize
  if pl.PyBytes_AsStringAndSize.isNil:
    load PyBytes_AsStringAndSize, "PyString_AsStringAndSize"
    load PyBytes_FromStringAndSize, "PyString_FromStringAndSize"

  load PyDict_Type
  load PyDict_New
  load PyDict_Size
  load PyDict_GetItemString
  load PyDict_SetItemString
  load PyDict_GetItem
  load PyDict_SetItem
  load PyDict_Keys
  load PyDict_Values
  load PyDict_Contains

  load PyErr_Clear
  load PyErr_SetString
  load PyErr_Occurred

  loadVar PyExc_TypeError

  load PyCapsule_New
  load PyCapsule_GetPointer

  load PyImport_ImportModule
  load PyEval_GetBuiltins
  load PyEval_GetGlobals
  load PyEval_GetLocals

  load PyCFunction_NewEx

  when not defined(release):
    load PyErr_Print

  load PyErr_Fetch
  load PyErr_NormalizeException
  load PyErr_GivenExceptionMatches

  load PyErr_NewException

  loadVar PyExc_ArithmeticError
  loadVar PyExc_AssertionError
  loadVar PyExc_AttributeError
  loadVar PyExc_EOFError
  loadVar PyExc_FloatingPointError
  loadVar PyExc_IndexError
  loadVar PyExc_IOError
  loadVar PyExc_KeyError
  loadVar PyExc_MemoryError
  loadVar PyExc_OSError
  loadVar PyExc_OverflowError
  loadVar PyExc_ValueError
  loadVar PyExc_ZeroDivisionError

  if pl.pythonVersion.major == 3:
    pl.PyDealloc = deallocPythonObj[PyTypeObject3]
  else:
    pl.PyDealloc = deallocPythonObj[PyTypeObject3] # Why does PyTypeObject3Obj work here and PyTypeObject2Obj does not???

when defined(windows):
  import winlean, os

  proc enumProcessModules(hProcess: HANDLE, lphModule: ptr LibHandle, cb: DWORD, cbNeeded: ptr DWORD): WINBOOL {.
    importc: "K32EnumProcessModules", dynlib: "kernel32", stdcall.}

  proc isPythonLibHandle(h: LibHandle): bool {.inline.} =
    # If module exports PyModule_AddObject we assume it to
    # be python.dll. Symbol choice is pretty arbitrary.
    let s = h.symAddr("PyModule_AddObject")
    not s.isNil

  proc findPythonDLL(): LibHandle {.inline.} =
    var mods: array[1024, LibHandle]
    var sz: DWORD
    let pr = getCurrentProcess()
    if enumProcessModules(pr, addr mods[0], 1024, addr sz) != 0:
      for i in 0 ..< sz:
        if isPythonLibHandle(mods[i]):
          return mods[i]
    raise newException(ValueError, "Could not find pythonXX.dll")

proc pythonLibHandleForThisProcess(): LibHandle {.inline.} =
  when defined(windows):
    findPythonDLL()
  else:
    loadLib()

iterator libPythonNames(): string {.closure.} =
  for v in ["3.11", "3.10", "3.9", "3.8", "3.7", "3.6", "3.5", "3",
            "",
            "2.7", "2.6", "2"]:
    when defined(macosx):
      yield "libpython" & v & ".dylib"
      yield "libpython" & v & "m.dylib"
    elif defined(windows):
      yield "python" & v.replace(".", "")
      yield "python" & v
    else:
      yield "libpython" & v & ".so"
      yield "libpython" & v & "m.so"
      when defined(linux):
        yield "libpython" & v & ".so.1"
        yield "libpython" & v & "m.so.1"

proc pythonLibHandleFromExternalLib(): LibHandle {.inline.} =
  when defined(windows):
    let pythonExe = findExe("python.exe")
    if pythonExe.len != 0:
      let d = parentDir(pythonExe)
      for lib in libPythonNames():
        result = loadLib(d / lib & ".dll", true)
        if not result.isNil:
          break

      if result.isNil:
        let s = toSeq(libPythonNames()).mapIt(d / it & ".dll").join(", ")
        raise newException(ValueError, "Could not load libpython. Tried " & s)
    else:
      raise newException(ValueError, "Could not load libpython. python.exe not found.")
  else:
    # Try this process first...
    result = loadLib()
    if not result.symAddr("PyTuple_New").isNil:
      return
    result = nil

    for lib in libPythonNames():
      result = loadLib(lib, true)
      if not result.isNil:
        break

    if result.isNil:
      let s = toSeq(libPythonNames()).join(", ")
      raise newException(ValueError, "Could not load libpython. Tried " & s)

proc loadPyLibFromThisProcess*(): PyLib {.inline.} =
  loadPyLibFromModule(pythonLibHandleForThisProcess())

proc loadModulesFromThisProcess(pyLibHandle: LibHandle) {.gcsafe.} =
  assert(pyLib.isNil, "Can't load built-in module after Python initialization")

  let
    pyMajorVer = pyLibHandle.getPyVersion().major
    PyImport_AppendInittab = cast[proc(name: cstring, initfuncPtr: PPyObject) : cint {.pyfunc.}](pyLibHandle.symAddr("PyImport_AppendInittab"))
  if PyImport_AppendInittab.isNil:
    symNotLoadedErr("PyImport_AppendInittab")

  {.gcsafe.}:
    for module in exportedModules:
      let
        moduleName = module.name
        modInitAddr = if pyMajorVer >= 3:
                        module.initAddr3
                      else:
                        module.initAddr2
        modInitFuncPtr = cast[PPyObject](modInitAddr)

      if modInitFuncPtr.isNil:
        let msg = "Init function pointer not found for module: " & $moduleName
        raise newException(ValueError, msg)

      let rc = PyImport_AppendInittab(cstring(moduleName), modInitFuncPtr)
      if rc != 0:
        raise newException(ValueError, "Could not add module: " & $moduleName)

proc initPyLib(m: LibHandle) =
  assert(pyLib.isNil)

  # Setup modules before initialization when not compiled as .so/.dll
  when not compileOption("app", "lib"):
    loadModulesFromThisProcess(m)

  let Py_InitializeEx = cast[proc(i: cint){.pyfunc.}](m.symAddr("Py_InitializeEx"))
  if Py_InitializeEx.isNil:
    symNotLoadedErr("Py_InitializeEx")

  Py_InitializeEx(0)

  when not compileOption("app", "lib"):
    let PySys_SetArgvEx = cast[proc(argc: cint, argv: pointer, updatepath: cint){.pyfunc.}](m.symAddr("PySys_SetArgvEx"))
    if not PySys_SetArgvEx.isNil:
      # TODO: Set sys.argv to actual command line params
      PySys_SetArgvEx(0, nil, 0)

  pyLib = loadPyLibFromModule(m)

proc pyInitLibPath*(pythonLibraryPath: string) =
  # Override nimpy python search, and use the provided library instead.
  # This will only have affect when the nim binary is exe, and not lib,
  # and only when no other calls to nimpy have been made before.
  if not pyLib.isNil: return
  let m = loadLib(pythonLibraryPath, true)
  if unlikely m.isNil:
    raise newException(ValueError, "Could not load libpython. Tried " & pythonLibraryPath)
  initPyLib(m)

# Hook for overriding which libpython to use for tests
const nimpyTestLibPython {.strdefine.} = ""

proc initPyThreadFrame() =
  when nimpyTestLibPython.len != 0:
    if unlikely pyLib.isNil:
      echo "Testing libpython: ", nimpyTestLibPython
      pyInitLibPath(nimpyTestLibPython)

  if unlikely pyLib.isNil:
    initPyLib(pythonLibHandleFromExternalLib())

  # https://stackoverflow.com/questions/42974139/valueerror-call-stack-is-not-deep-enough-when-calling-ipython-embed-method
  # needed for eval and stuff like pandas.query() otherwise crash (call stack is not deep enough)
  #
  # XXX Unfortunately this doesn't work with python 3.11 and later.
  pyThreadFrameInited = true

  let
    pyThreadStateGet = cast[proc(): pointer {.pyfunc.}](pyLib.module.symAddr("PyThreadState_Get"))
    pyThread = pyThreadStateGet()

  case pyLib.pythonVersion.major
  of 2:
    if not cast[ptr PyThreadState2](pyThread).frame.isNil: return
  of 3:
    if pyLib.pythonVersion < (3, 11, 0):
      if not cast[ptr PyThreadState3](pyThread).frame.isNil: return
  else:
    doAssert(false, "unreachable")

  let
    pyImportAddModule = cast[proc(str: cstring): pointer {.pyfunc.}](pyLib.module.symAddr("PyImport_AddModule"))
    pyModuleGetDict = cast[proc(p: pointer): pointer {.pyfunc.}](pyLib.module.symAddr("PyModule_GetDict"))
    pyCodeNewEmpty = cast[proc(str1, str2: cstring; i: cint): pointer {.pyfunc.}](pyLib.module.symAddr("PyCode_NewEmpty"))
    pyFrameNew = cast[proc(p1, p2, p3, p4: pointer): pointer {.pyfunc.}](pyLib.module.symAddr("PyFrame_New"))

  if not pyImportAddModule.isNil and not pyModuleGetDict.isNil and not pyCodeNewEmpty.isNil and not pyFrameNew.isNil:
    proc makeRootFrame(): pointer =
      let
        main_module = pyImportAddModule("__main__")
        main_dict = pyModuleGetDict(main_module)
        code_object = pyCodeNewEmpty("null.py", "f", 0)
      pyFrameNew(pyThread, code_object, main_dict, main_dict)

    case pyLib.pythonVersion.major
    of 2:
      cast[ptr PyThreadState2](pyThread).frame = makeRootFrame()
    of 3:
      if pyLib.pythonVersion < (3, 11, 0):
        cast[ptr PyThreadState3](pyThread).frame = makeRootFrame()
    else:
      doAssert(false, "unreachable")

proc initPyLibIfNeeded*() {.inline.} =
  if unlikely(not pyThreadFrameInited):
    initPyThreadFrame()
