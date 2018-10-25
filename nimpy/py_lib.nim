import dynlib, sequtils, strutils, complex, py_types

type
    PyLib* = ref object
        module*: LibHandle

        Py_BuildValue*: proc(f: cstring): PPyObject {.cdecl, varargs.}
        PyTuple_New*: proc(sz: Py_ssize_t): PPyObject {.cdecl.}
        PyTuple_Size*: proc(f: PPyObject): Py_ssize_t {.cdecl.}
        PyTuple_GetItem*: proc(f: PPyObject, i: Py_ssize_t): PPyObject {.cdecl.}
        PyTuple_SetItem*: proc(f: PPyObject, i: Py_ssize_t, v: PPyObject): cint {.cdecl.}

        Py_None*: PPyObject
        PyType_Ready*: proc(f: PyTypeObject): cint {.cdecl.}
        PyType_GenericNew*: proc(f: PyTypeObject, a, b: PPyObject): PPyObject {.cdecl.}
        PyModule_AddObject*: proc(m: PPyObject, n: cstring, o: PPyObject): cint {.cdecl.}

        # PyList_Check*: proc(l: PPyObject): cint {.cdecl.}
        PyList_New*: proc(size: Py_ssize_t): PPyObject {.cdecl.}
        PyList_Size*: proc(l: PPyObject): Py_ssize_t {.cdecl.}
        PyList_GetItem*: proc(l: PPyObject, index: Py_ssize_t): PPyObject {.cdecl.}
        PyList_SetItem*: proc(l: PPyObject, index: Py_ssize_t, i: PPyObject): cint {.cdecl.}

        PyObject_Call*: proc(callable_object, args, kw: PPyObject): PPyObject {.cdecl.}
        PyObject_IsTrue*: proc(o: PPyObject): cint {.cdecl.}
        # PyObject_HasAttrString*: proc(o: PPyObject, name: cstring): cint {.cdecl.}
        PyObject_GetAttrString*: proc(o: PPyObject, name: cstring): PPyObject {.cdecl.}
        PyObject_SetAttrString*: proc(o: PPyObject, name: cstring, v: PPyObject): cint {.cdecl.}
        PyObject_Dir*: proc(o: PPyObject): PPyObject {.cdecl.}
        PyObject_Str*: proc(o: PPyObject): PPyObject {.cdecl.}
        PyObject_GetIter*: proc(o: PPyObject): PPyObject {.cdecl.}
        PyObject_GetItem*: proc(o, k: PPyObject): PPyObject {.cdecl.}
        PyObject_SetItem*: proc(o, k, v: PPyObject): cint {.cdecl.}
        PyObject_GetBuffer*: proc(o: PPyObject, b: var RawPyBuffer, flags: cint): cint {.cdecl.}
        PyBuffer_Release*: proc(b: var RawPyBuffer) {.cdecl.}

        PyIter_Next*: proc(o: PPyObject): PPyObject {.cdecl.}

        PyLong_AsLongLong*: proc(l: PPyObject): int64 {.cdecl.}
        PyFloat_AsDouble*: proc(l: PPyObject): cdouble {.cdecl.}
        PyBool_FromLong*: proc(v: clong): PPyObject {.cdecl.}

        PyFloat_Type*: PyTypeObject
        PyComplex_Type*: PyTypeObject
        PyCapsule_Type*: PyTypeObject
        PyTuple_Type*: PyTypeObject
        PyList_Type*: PyTypeObject
        PyBytes_Type*: PyTypeObject
        PyUnicode_Type*: PyTypeObject

        PyType_IsSubtype*: proc(t1, t2: PyTypeObject): cint {.cdecl.}

        PyComplex_AsCComplex*: proc(op: PPyObject): Complex {.cdecl.}
        PyComplex_RealAsDouble*: proc(op: PPyObject): cdouble {.cdecl.}
        PyComplex_ImagAsDouble*: proc(op: PPyObject): cdouble {.cdecl.}

        PyUnicode_AsUTF8String*: proc(o: PPyObject): PPyObject {.cdecl.}
        PyBytes_AsStringAndSize*: proc(o: PPyObject, s: ptr ptr char, len: ptr Py_ssize_t): cint {.cdecl.}

        PyDict_Type*: PyTypeObject
        PyDict_New*: proc(): PPyObject {.cdecl.}
        PyDict_Size*: proc(d: PPyObject): Py_ssize_t {.cdecl.}
        PyDict_GetItemString*: proc(o: PPyObject, k: cstring): PPyObject {.cdecl.}
        PyDict_SetItemString*: proc(o: PPyObject, k: cstring, v: PPyObject): cint {.cdecl.}
        PyDict_GetItem*: proc(o: PPyObject, k: PPyObject): PPyObject {.cdecl.}
        PyDict_SetItem*: proc(o: PPyObject, k, v: PPyObject): cint {.cdecl.}
        PyDict_Keys*: proc(o: PPyObject): PPyObject {.cdecl.}
        PyDict_Values*: proc(o: PPyObject): PPyObject {.cdecl.}

        PyDealloc*: proc(o: PPyObject) {.nimcall.}

        PyErr_Clear*: proc() {.cdecl.}
        PyErr_SetString*: proc(o: PPyObject, s: cstring) {.cdecl.}
        PyErr_Occurred*: proc(): PPyObject {.cdecl.}
        PyExc_TypeError*: PPyObject

        PyCapsule_New*: proc(p: pointer, name: cstring, destr: proc(o: PPyObject) {.cdecl.}): PPyObject {.cdecl.}
        PyCapsule_GetPointer*: proc(c: PPyObject, name: cstring): pointer {.cdecl.}

        PyImport_ImportModule*: proc(name: cstring): PPyObject {.cdecl.}
        PyEval_GetBuiltins*: proc(): PPyObject {.cdecl.}
        PyEval_GetGlobals*: proc(): PPyObject {.cdecl.}
        PyEval_GetLocals*: proc(): PPyObject {.cdecl.}

        pythonVersion*: int

        when not defined(release):
            PyErr_Print: proc() {.cdecl.}
        PyErr_Fetch*: proc(ptype, pvalue, ptraceback: ptr PPyObject) {.cdecl.}
        PyErr_NormalizeException*: proc(ptype, pvalue, ptraceback: ptr PPyObject) {.cdecl.}

        PyErr_GivenExceptionMatches*: proc(given, exc: PPyObject): cint {.cdecl.}

        PyExc_BaseException*: PPyObject # should always match any exception?
        PyExc_Exception*: PPyObject
        PyExc_ArithmeticError*: PPyObject
        PyExc_FloatingPointError*: PPyObject
        PyExc_OverflowError*: PPyObject
        PyExc_ZeroDivisionError*: PPyObject
        PyExc_AssertionError*: PPyObject
        PyExc_OSError*: PPyObject
        PyExc_IOError*: PPyObject # in Python 3 IOError *is* OSError
        PyExc_ValueError*: PPyObject
        PyExc_EOFError*: PPyObject
        PyExc_MemoryError*: PPyObject
        PyExc_IndexError*: PPyObject
        PyExc_KeyError*: PPyObject



var pyObjectStartOffset*: uint
var pyLib*: PyLib


proc to*(p: PPyObject, t: typedesc): ptr t {.inline.} =
    result = cast[ptr t](cast[uint](p) + pyObjectStartOffset)

proc deallocPythonObj[TypeObjectType](p: PPyObject) =
    let ob = p.to(PyObjectObj)
    let t = cast[TypeObjectType](ob.ob_type)
    t.tp_dealloc(cast[PPyObject](p))

proc symNotLoadedErr(s: cstring) =
    raise newException(Exception, "Symbol not loaded: " & $s)

proc loadPyLibFromModule(m: LibHandle): PyLib =
    assert(not m.isNil)
    result.new()
    let pl = result
    pl.module = m
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
    load PyObject_GetBuffer
    load PyBuffer_Release

    load PyIter_Next

    load PyLong_AsLongLong
    load PyFloat_AsDouble
    load PyBool_FromLong

    load PyFloat_Type
    load PyComplex_Type
    load PyCapsule_Type
    load PyTuple_Type
    load PyList_Type
    load PyUnicode_Type
    maybeLoad PyBytes_Type
    if pl.PyBytes_Type.isNil:
        # Needed for compatibility with Python 2
        load PyBytes_Type, "PyString_Type"

    load PyType_IsSubtype

    maybeLoad PyComplex_AsCComplex
    if pl.PyComplex_AsCComplex.isNil:
        load PyComplex_RealAsDouble
        load PyComplex_ImagAsDouble

    maybeLoad PyUnicode_AsUTF8String
    if pl.PyUnicode_AsUTF8String.isNil:
        maybeLoad PyUnicode_AsUTF8String, "PyUnicodeUCS4_AsUTF8String"
        if pl.PyUnicode_AsUTF8String.isNil:
            load PyUnicode_AsUTF8String, "PyUnicodeUCS2_AsUTF8String"

    pl.pythonVersion = 3

    maybeLoad PyBytes_AsStringAndSize
    if pl.PyBytes_AsStringAndSize.isNil:
        load PyBytes_AsStringAndSize, "PyString_AsStringAndSize"
        pl.pythonVersion = 2

    load PyDict_Type
    load PyDict_New
    load PyDict_Size
    load PyDict_GetItemString
    load PyDict_SetItemString
    load PyDict_GetItem
    load PyDict_SetItem
    load PyDict_Keys
    load PyDict_Values

    if pl.pythonVersion == 3:
        pl.PyDealloc = deallocPythonObj[PyTypeObject3]
    else:
        pl.PyDealloc = deallocPythonObj[PyTypeObject3] # Why does PyTypeObject3Obj work here and PyTypeObject2Obj does not???

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

    when not defined(release):
        load PyErr_Print

    load PyErr_Fetch
    load PyErr_NormalizeException
    load PyErr_GivenExceptionMatches

    loadVar PyExc_ArithmeticError
    loadVar PyExc_FloatingPointError
    loadVar PyExc_OverflowError
    loadVar PyExc_ZeroDivisionError
    loadVar PyExc_AssertionError
    loadVar PyExc_OSError
    loadVar PyExc_IOError
    loadVar PyExc_ValueError
    loadVar PyExc_EOFError
    loadVar PyExc_MemoryError
    loadVar PyExc_IndexError
    loadVar PyExc_KeyError

when defined(windows):
    import winlean
    proc getModuleHandle(path: cstring): LibHandle {.
        importc: "GetModuleHandle", header: "<windows.h>", stdcall.}

    proc enumProcessModules(hProcess: HANDLE, lphModule: ptr Handle, cb: DWORD, cbNeeded: ptr DWORD): WINBOOL {.
        importc: "K32EnumProcessModules", dynlib: "kernel32", stdcall.}

    proc getModuleFileName(handle: Handle, buf: cstring, size: int32): int32 {.
        importc: "GetModuleFileNameA", dynlib: "kernel32", stdcall.}

    proc findPythonDLL(): string {.inline.} =
        var mods: array[1024, Handle]
        var sz: DWORD
        let pr = getCurrentProcess()
        if enumProcessModules(pr, addr mods[0], 1024, addr sz) != 0:
            var fn = newString(1024)
            for i in 0 ..< sz:
                fn.setLen(1024)
                let ln = getModuleFileName(mods[i], cstring(addr fn[0]), 1024)
                if ln != 0:
                    if ln < 1024:
                        fn.setLen(ln)
                    const suffixLen = "\\pythonXX.dll".len
                    if fn.endsWith(".dll") and fn.rfind("\\python") == fn.len - suffixLen:
                        return fn
        raise newException(Exception, "Could not find pythonXX.dll")

proc pythonLibHandleForThisProcess(): LibHandle {.inline.} =
    when defined(windows):
        getModuleHandle(findPythonDLL())
    else:
        loadLib()

iterator libPythonNames(): string {.closure.} =
    for v in ["3", "3.6m", "3.5m", "", "2", "2.7"]:
        var libname = when defined(macosx):
                "libpython" & v & ".dylib"
            elif defined(windows):
                "python" & v
            else:
                "libpython" & v & ".so"
        yield libname

        when defined(linux):
            # try appending ".1" to the libname
            libname &= ".1"
            yield libname

proc pythonLibHandleFromExternalLib(): LibHandle {.inline.} =
    when not defined(windows):
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
        raise newException(Exception, "Could not load python libpython. Tried " & s)

proc loadPyLibFromThisProcess*(): PyLib {.inline.} =
  loadPyLibFromModule(pythonLibHandleForThisProcess())

proc initPyLib() =
    assert(pyLib.isNil)

    let m = pythonLibHandleFromExternalLib()

    let Py_InitializeEx = cast[proc(i: cint){.cdecl.}](m.symAddr("Py_InitializeEx"))
    if Py_InitializeEx.isNil:
        symNotLoadedErr("Py_InitializeEx")

    Py_InitializeEx(0)

    let PySys_SetArgvEx = cast[proc(argc: cint, argv: pointer, updatepath: cint){.cdecl.}](m.symAddr("PySys_SetArgvEx"))
    if not PySys_SetArgvEx.isNil:
        PySys_SetArgvEx(0, nil, 0)

    pyLib = loadPyLibFromModule(m)

proc initPyLibIfNeeded*() {.inline.} =
    if unlikely pyLib.isNil:
        initPyLib()
