import dynlib, macros, ospaths, strutils

type
    PyObject* = distinct pointer

    PyCFunction = proc(s, a: PyObject): PyObject {.cdecl.}

    PyMethodDef = object
        ml_name: cstring
        ml_meth: PyCFunction
        ml_flags: cint
        ml_doc: cstring

type # Python3
    PyModuleDef_Slot = object
        slot: cint
        value: pointer

    Py_ssize_t = csize

    PyObject_HEAD_EXTRA = object
        ob_next: pointer
        ob_prev: pointer

    PyObjectObj {.pure, inheritable.} = object
        # extra: PyObject_HEAD_EXTRA # in runtime depends on traceRefs. see pyAlloc
        ob_refcnt: Py_ssize_t
        ob_type: pointer

    PyObjectVarHeadObj = object of PyObjectObj
        ob_size: Py_ssize_t

    PyModuleDef_Base = object
        ob_base: PyObjectObj
        m_init: proc(): PyObject {.cdecl.}
        m_index: Py_ssize_t
        m_copy: PyObject

    PyModuleDef = object
        m_base: PyModuleDef_Base
        m_name: cstring
        m_doc: cstring
        m_size: Py_ssize_t
        m_methods: ptr PyMethodDef
        m_slots: ptr PyModuleDef_Slot
        m_traverse: pointer

        m_clear: pointer
        m_free: pointer

    Py_buffer* = object
        buf: pointer
        obj: PyObject
        len: Py_ssize_t
        itemsize: Py_ssize_t
        readonly: cint
        ndim: cint
        format: cstring
        shape: ptr Py_ssize_t
        strides: ptr Py_ssize_t
        suboffsets: ptr Py_ssize_t
        smalltable: array[2, Py_ssize_t] # Don't refer! not available in python 3
        internal: pointer # Don't ever refer

    Destructor = proc(o: PyObject) {.cdecl.}
    Printfunc = proc(o: PyObject, f: File, c: cint): cint {.cdecl}
    Getattrfunc = proc(o: PyObject, a: cstring): PyObject {.cdecl.}
    Getattrofunc = proc(o, a: PyObject): PyObject {.cdecl.}
    Setattrfunc = proc(o: PyObject, a: cstring, at: PyObject): cint {.cdecl.}
    Setattrofunc = proc(o, a, at: PyObject): cint {.cdecl.}
    Reprfunc = proc(o: PyObject): PyObject {.cdecl.}
    Richcmpfunc = proc(a, b: PyObject, c: cint): PyObject {.cdecl.}
    Getiterfunc = proc(a: PyObject): PyObject {.cdecl.}
    Iternextfunc = proc(a: PyObject): PyObject {.cdecl.}
    Descrgetfunc = proc(a, b, c: PyObject): PyObject {.cdecl.}
    Descrsetfunc = proc(a, b, c: PyObject): cint {.cdecl.}
    Initproc = proc(a, b, c: PyObject): cint {.cdecl.}
    Newfunc = proc(typ: PyObject, a, b: PyObject): PyObject {.cdecl.}
    Allocfunc = proc(typ: PyObject, sz: Py_ssize_t): PyObject {.cdecl.}

    # 3
    # typedef PyObject *(*getattrfunc)(PyObject *, char *);
    # typedef PyObject *(*getattrofunc)(PyObject *, PyObject *);
    # typedef int (*setattrfunc)(PyObject *, char *, PyObject *);
    # typedef int (*setattrofunc)(PyObject *, PyObject *, PyObject *);
    # typedef PyObject *(*reprfunc)(PyObject *);
    # typedef Py_hash_t (*hashfunc)(PyObject *);
    # typedef PyObject *(*richcmpfunc) (PyObject *, PyObject *, int);
    # typedef PyObject *(*getiterfunc) (PyObject *);
    # typedef PyObject *(*iternextfunc) (PyObject *);
    # typedef PyObject *(*descrgetfunc) (PyObject *, PyObject *, PyObject *);
    # typedef int (*descrsetfunc) (PyObject *, PyObject *, PyObject *);
    # typedef int (*initproc)(PyObject *, PyObject *, PyObject *);
    # typedef PyObject *(*newfunc)(struct _typeobject *, PyObject *, PyObject *);
    # typedef PyObject *(*allocfunc)(struct _typeobject *, Py_ssize_t);

    # 2
    # typedef PyObject *(*getattrfunc)(PyObject *, char *);
    # typedef PyObject *(*getattrofunc)(PyObject *, PyObject *);
    # typedef int (*setattrfunc)(PyObject *, char *, PyObject *);
    # typedef int (*setattrofunc)(PyObject *, PyObject *, PyObject *);
    # typedef int (*cmpfunc)(PyObject *, PyObject *);
    # typedef PyObject *(*reprfunc)(PyObject *);
    # typedef long (*hashfunc)(PyObject *);
    # typedef PyObject *(*richcmpfunc) (PyObject *, PyObject *, int);
    # typedef PyObject *(*getiterfunc) (PyObject *);
    # typedef PyObject *(*iternextfunc) (PyObject *);
    # typedef PyObject *(*descrgetfunc) (PyObject *, PyObject *, PyObject *);
    # typedef int (*descrsetfunc) (PyObject *, PyObject *, PyObject *);
    # typedef int (*initproc)(PyObject *, PyObject *, PyObject *);
    # typedef PyObject *(*newfunc)(struct _typeobject *, PyObject *, PyObject *);
    # typedef PyObject *(*allocfunc)(struct _typeobject *, Py_ssize_t);

    PyTypeObject3 = ptr object of PyObjectVarHeadObj
        tp_name: cstring
        tp_basicsize, tp_itemsize: Py_ssize_t

        # Methods to implement standard operations
        tp_dealloc: Destructor
        tp_print: Printfunc

        tp_getattr: Getattrfunc
        tp_setattr: Setattrfunc

        tp_as_async: pointer

        tp_repr: Reprfunc

        # Method suites for standard classes

        tp_as_number: pointer
        tp_as_sequence: pointer
        tp_as_mapping: pointer


        # More standard operations (here for binary compatibility)

        tp_hash: pointer # hashfunc
        tp_call: pointer # ternaryfunc
        tp_str: Reprfunc
        tp_getattro: Getattrofunc
        tp_setattro: Setattrofunc

        # Functions to access object as input/output buffer
        tp_as_buffer: pointer

        # Flags to define presence of optional/expanded features
        tp_flags: culong

        tp_doc: cstring

        # call function for all accessible objects
        tp_traverse: pointer

        # delete references to contained objects
        tp_clear: pointer # inquiry

        # rich comparisons
        tp_richcompare: Richcmpfunc

        # weak reference enabler
        tp_weaklistoffset: Py_ssize_t

        # Iterators
        tp_iter: Getiterfunc
        tp_iternext: Iternextfunc

        # Attribute descriptor and subclassing stuff
        tp_methods: ptr PyMethodDef
        tp_members: pointer # ptr PyMemberDef
        tp_getset: pointer # ptr PyGetSetDef

        tp_base: PyTypeObject3
        tp_dict: PyObject

        tp_descr_get: Descrgetfunc
        tp_descr_set: Descrsetfunc
        tp_dictoffset: Py_ssize_t

        tp_init: Initproc
        tp_alloc: Allocfunc
        tp_new: Newfunc

        tp_free: pointer # freefunc
        tp_is_gc: pointer # inquiry /* For PyObject_IS_GC */

        tp_bases: ptr PyObjectObj
        tp_mro: PyObject # method resolution order. array?
        tp_cache: PyObject # array?
        tp_subclasses: ptr PyObjectObj
        tp_weaklist: ptr PyObjectObj

        tp_del: Destructor

        # Type attribute cache version tag. Added in version 2.6 */
        tp_version_tag: cuint
        tp_finalize: Destructor

    PyTypeObject = PyTypeObject3

proc isNil*(p: PyObject): bool {.borrow.}

var Py_BuildValue*: proc(f: cstring): PyObject {.cdecl, varargs.}
var PyTuple_Size*: proc(f: PyObject): Py_ssize_t {.cdecl.}
var PyTuple_GetItem*: proc(f: PyObject, i: Py_ssize_t): PyObject {.cdecl.}
var PyArg_ParseTuple*: proc(f: PyObject, fmt: cstring): cint {.cdecl, varargs.}
var Py_None*: PyObject
var PyType_Ready*: proc(f: PyTypeObject): cint {.cdecl.}

# var PyList_Check*: proc(l: PyObject): cint {.cdecl.}
var PyList_New*: proc(size: Py_ssize_t): PyObject {.cdecl.}
var PyList_Size*: proc(l: PyObject): Py_ssize_t {.cdecl.}
var PyList_GetItem*: proc(l: PyObject, index: Py_ssize_t): PyObject {.cdecl.}
var PyList_SetItem*: proc(l: PyObject, index: Py_ssize_t, i: PyObject): cint {.cdecl.}

var PyLong_AsLongLong*: proc(l: PyObject): int64 {.cdecl.}
var PyFloat_AsDouble*: proc(l: PyObject): cdouble {.cdecl.}
var PyBool_FromLong*: proc(v: clong): PyObject {.cdecl.}

type PyModuleDesc = object
    name: cstring
    doc: cstring
    methods: seq[PyMethodDef]
    types: seq[PyTypeObject]

proc addMethod(m: var PyModuleDesc, name, doc: cstring, f: PyCFunction) =
    m.methods.add(PyMethodDef(ml_name: name, ml_meth: f, ml_flags: 1, ml_doc: doc))

proc initPythonModuleDesc(m: var PyModuleDesc, name, doc: cstring) =
    m.name = name
    m.doc = doc
    m.methods = @[]

var gLibModule: LibHandle
var traceRefs: bool

proc pyAlloc(sz: int): PyObject =
    var sz = sz
    if traceRefs:
        sz += sizeof(PyObject_HEAD_EXTRA)
    result = cast[PyObject](alloc0(sz))

proc to(p: PyObject, t: typedesc): ptr t {.inline.} =
    if traceRefs:
        result = cast[ptr t](cast[uint](p) + sizeof(PyObject_HEAD_EXTRA).uint)
    else:
        result = cast[ptr t](p)

proc incRef(p: PyObject) {.inline.} =
    inc p.to(PyObjectObj).ob_refcnt

proc initCommon(m: var PyModuleDesc) =
    gLibModule = loadLib()

    if not (gLibModule.symAddr("PyModule_Create2").isNil or
            gLibModule.symAddr("Py_InitModule4_64").isNil or
            gLibModule.symAddr("Py_InitModule4").isNil):
        traceRefs = true

    template load(v: typed, name: cstring) =
        v = cast[type(v)](gLibModule.symAddr(name))
        if v.isNil:
            raise newException(Exception, "Symbol not loaded: " & $name)

    load Py_BuildValue, "_Py_BuildValue_SizeT"
    load PyTuple_Size, "PyTuple_Size"
    load PyTuple_GetItem, "PyTuple_GetItem"
    load PyArg_ParseTuple, "_PyArg_ParseTuple_SizeT"
    load Py_None, "_Py_NoneStruct"
    load PyType_Ready, "PyType_Ready"
    # load PyList_Check, "PyList_Check"
    load PyList_New, "PyList_New"
    load PyList_Size, "PyList_Size"
    load PyList_GetItem, "PyList_GetItem"
    load PyList_SetItem, "PyList_SetItem"
    load PyLong_AsLongLong, "PyLong_AsLongLong"
    load PyFloat_AsDouble, "PyFloat_AsDouble"
    load PyBool_FromLong, "PyBool_FromLong"

    m.methods.add(PyMethodDef()) # Add sentinel

proc initModuleTypes(p: PyObject, m: var PyModuleDesc) =
    # let ty = cast[PyTypeObject3](pyAlloc(sizeof(PyTypeObject3)))
    # ty.tp_name = "simple.TestType"
    # ty.tp_basicsize = 4
    # ty.tp_flags =
    discard

proc initModule2(m: var PyModuleDesc) {.inline.} =
    initCommon(m)
    const PYTHON_ABI_VERSION = 1013

    var Py_InitModule4: proc(name: cstring, methods: ptr PyMethodDef, doc: cstring, self: PyObject, apiver: cint): PyObject {.cdecl.}
    Py_InitModule4 = cast[type(Py_InitModule4)](gLibModule.symAddr("Py_InitModule4"))
    if Py_InitModule4.isNil:
        Py_InitModule4 = cast[type(Py_InitModule4)](gLibModule.symAddr("Py_InitModule4_64"))
    if not Py_InitModule4.isNil:
        let py = Py_InitModule4(m.name, addr m.methods[0], m.doc, nil, PYTHON_ABI_VERSION)
        initModuleTypes(py, m)

proc initPyModule(p: ptr PyModuleDef, m: var PyModuleDesc) {.inline.} =
    p.m_base.ob_base.ob_refcnt = 1
    p.m_name = m.name
    p.m_doc = m.doc
    p.m_size = -1
    p.m_methods = addr m.methods[0]

proc initModule3(m: var PyModuleDesc): PyObject {.inline.} =
    initCommon(m)
    const PYTHON_ABI_VERSION = 3
    var PyModule_Create2: proc(m: PyObject, apiver: cint): PyObject {.cdecl.}
    PyModule_Create2 = cast[type(PyModule_Create2)](gLibModule.symAddr("PyModule_Create2"))

    if PyModule_Create2.isNil:
        PyModule_Create2 = cast[type(PyModule_Create2)](gLibModule.symAddr("PyModule_Create2TraceRefs"))

    if not PyModule_Create2.isNil:
        var pymod = pyAlloc(sizeof(PyModuleDef))
        initPyModule(pymod.to(PyModuleDef), m)
        result = PyModule_Create2(pymod, PYTHON_ABI_VERSION)
        initModuleTypes(result, m)

proc NimMain() {.importc.}

{.push stackTrace: off.}
proc initModuleAux2(m: var PyModuleDesc) =
    NimMain()
    initModule2(m)

proc initModuleAux3(m: var PyModuleDesc): PyObject =
    NimMain()
    initModule3(m)
{.pop.}

template declarePyModuleIfNeeded(name: untyped) =
    when not declared(gPythonLocalModuleDesc):
        const nameStr = astToStr(name)

        var gPythonLocalModuleDesc {.inject.}: PyModuleDesc
        initPythonModuleDesc(gPythonLocalModuleDesc, nameStr, nil)
        {.push stackTrace: off.}
        proc `py2init name`() {.exportc: "init" & nameStr.} =
            initModuleAux2(gPythonLocalModuleDesc)

        proc `py3init name`(): PyObject {.exportc: "PyInit_" & nameStr.} =
            initModuleAux3(gPythonLocalModuleDesc)
        {.pop.}

################################################################################
################################################################################
################################################################################

template staticJoin(s: varargs[string]): cstring =
    const r: cstring = s.join()
    r

type PyValue[T] = object
    when T is string:
        buf: Py_buffer
    elif T is seq|array:
        val: PyObject
    elif T is int8|bool:
        val: int16
    else:
        val: T

proc toString*(b: Py_buffer): string =
    if not b.buf.isNil:
        let ln = b.len
        result = newString(ln)
        if ln != 0:
            copyMem(addr result[0], b.buf, ln)


template pySignatureForType(t: typedesc[string]): string = "s*"
template pySignatureForType(t: typedesc[PyObject]): string = "O"

template pySignatureForType(t: typedesc[bool]): string = "h"
template pySignatureForType(t: typedesc[int8]): string = "h"
template pySignatureForType(t: typedesc[int16]): string = "h"
template pySignatureForType(t: typedesc[int32]): string = "i"
template pySignatureForType(t: typedesc[int64]): string = "L"
template pySignatureForType(t: typedesc[int]): string =
    when sizeof(int) == sizeof(int32):
        pySignatureForType(int32)
    elif sizeof(int) == sizeof(int64):
        pySignatureForType(int64)
    else:
        {.error: "Unexpected int size".}

template pySignatureForType(t: typedesc[uint8]): string = "B"
template pySignatureForType(t: typedesc[uint16]): string = "H"
template pySignatureForType(t: typedesc[uint32]): string = "I"
template pySignatureForType(t: typedesc[uint64]): string = "K"
template pySignatureForType(t: typedesc[uint]): string =
    when sizeof(uint) == sizeof(uint32):
        pySignatureForType(uint32)
    elif sizeof(uint) == sizeof(uint64):
        pySignatureForType(uint64)
    else:
        {.error: "Unexpected int size".}


template pySignatureForType(t: typedesc[float32]): string = "f"
template pySignatureForType(t: typedesc[float64]): string = "d"
template pySignatureForType(t: typedesc[seq]): string = "O"
template pySignatureForType(t: typedesc[array]): string = "O"

proc pyObjToNim[T: int|int32|int64|int16|uint32|uint64|uint16|uint](o: PyObject, r: var T) {.inline.} =
    r = T(PyLong_AsLongLong(o))

proc pyObjToNim[T: float|float32|float64](o: PyObject, r: var T) {.inline.} =
    r = T(PyFloat_AsDouble(o))

proc pyObjToNim[T](o: PyObject, s: var seq[T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(PyList_Size(o))
    assert(sz >= 0)
    s = newSeq[T](sz)
    for i in 0 ..< sz:
        pyObjToNim(PyList_GetItem(o, i), s[i])

proc pyObjToNim[T, I](o: PyObject, s: var array[I, T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(PyList_Size(o))
    assert(sz == s.len)
    for i in 0 ..< sz:
        pyObjToNim(PyList_GetItem(o, i), s[i])

proc pyValueToNim[T](v: PyValue[T]): T {.inline.} =
    when T is string:
        v.buf.toString()
    elif T is seq|array:
        pyObjToNim(v.val, result)
    elif T is int8|bool:
        T(v.val)
    else:
        v.val

proc strToPyObject(s: string): PyObject {.inline.} =
    var cs: cstring
    var ln: cint
    if not s.isNil:
        cs = s
        ln = cint(s.xlen)
    Py_BuildValue("s#", cs, ln)

iterator arguments(prc: NimNode): tuple[idx: int, name, typ, default: NimNode] =
    let p = prc.params
    var iParam = 0
    for i in 1 ..< p.len:
        let pp = p[i]
        for j in 0 .. pp.len - 3:
            yield (iParam, pp[j], pp[^2], pp[^1])
            inc iParam

proc nimArrToPy[T](s: openarray[T]): PyObject

template nimValueToPy[T](v: T): PyObject =
    when T is void:
        v
        incRef(Py_None)
        Py_None
    elif T is string:
        strToPyObject(v)
    elif T is int32:
        Py_BuildValue("i", v)
    elif T is int64:
        Py_BuildValue("L", v)
    elif T is int:
        when sizeof(int) == sizeof(int32):
            Py_BuildValue("i", v)
        elif sizeof(int) == sizeof(int64):
            Py_BuildValue("L", v)
        else:
            {.error: "Unkown int size".}
    elif T is int8:
        Py_BuildValue("b", v)
    elif T is uint8:
        Py_BuildValue("B", v)
    elif T is int32:
        Py_BuildValue("i", v)
    elif T is uint32:
        Py_BuildValue("I", v)
    elif T is int16:
        Py_BuildValue("h", v)
    elif T is uint16:
        Py_BuildValue("H", v)
    elif T is int64:
        Py_BuildValue("L", v)
    elif T is uint64:
        Py_BuildValue("K", v)
    elif T is float32 | float | float64:
        Py_BuildValue("d", float64(v))
    elif T is seq|array:
        nimArrToPy(v)
    elif T is bool:
        PyBool_FromLong(clong(v))
    else:
        {.error: "Unkown return type".}

proc nimArrToPy[T](s: openarray[T]): PyObject =
    let sz = s.len
    result = PyList_New(sz)
    for i in 0 ..< sz:
        let o = nimValueToPy(s[i])
        discard PyList_SetItem(result, i, o)

proc makeWrapper(name, prc: NimNode): NimNode =
    let selfIdent = newIdentNode("self")
    let argsIdent = newIdentNode("args")

    result = newProc(name, params = [bindSym"PyObject", newIdentDefs(selfIdent, bindSym"PyObject"), newIdentDefs(argsIdent, bindSym"PyObject")])
    result.addPragma(newIdentNode("cdecl"))
    result.body = newStmtList()

    let pyValueVarSection = newNimNode(nnkVarSection)
    result.body.add(pyValueVarSection)

    let format = newCall(bindSym"staticJoin")

    let parseCall = newCall(bindSym"PyArg_ParseTuple", argsIdent, format)
    let origCall = newCall(prc.name)

    for a in prc.arguments:
        let argIdent = newIdentNode("arg" & $a.idx & $a.name)
        pyValueVarSection.add(newIdentDefs(argIdent, newNimNode(nnkBracketExpr).add(bindSym"PyValue", a.typ)))
        format.add(newCall(bindSym"pySignatureForType", a.typ))
        parseCall.add(newCall(bindSym"addr", argIdent))
        origCall.add(newCall(bindSym"pyValueToNim", argIdent))

    result.body.add quote do:
        if `parseCall` == 0:
            return nil
        nimValueToPy(`origCall`)

proc exportProc(prc: NimNode, modulename: string, wrap: bool): NimNode =
    let modulename = modulename.splitFile.name

    var comment: NimNode
    if prc.body.kind == nnkStmtList and prc.body.len != 0 and prc.body[0].kind == nnkCommentStmt:
        comment = newLit($prc.body[0])
    else:
        comment = newNilLit()

    if not wrap:
        prc.addPragma(newIdentNode("cdecl"))

    result = newStmtList(prc)
    result.add(newCall(bindSym("declarePyModuleIfNeeded"), newIdentNode(modulename)))

    var procIdent = prc.name
    let procName = $procIdent
    if wrap:
        procIdent = newIdentNode(procName & "Py_wrapper")
        result.add(makeWrapper(procIdent, prc))

    result.add(newCall(bindSym"addMethod", newIdentNode("gPythonLocalModuleDesc"), newLit(procName), comment, procIdent))
    # echo "procname: ", procName
    # echo repr result

macro exportType(typ: typed, modulename: static[string], wrap: static[bool]): untyped =
    discard

macro exportpyAux(prc: untyped, modulename: static[string], wrap: static[bool]): untyped =
    exportProc(prc, modulename, wrap)


template exportpyraw*(prc: untyped) = exportpyAux(prc, instantiationInfo().filename, false)
template exportpy*(typ: typedesc) = exportType(typ, instantiationInfo().filename, true)
template exportpy*(prc: untyped{nkProcDef}) = exportpyAux(prc, instantiationInfo().filename, true)

