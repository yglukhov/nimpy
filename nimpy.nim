import dynlib, macros, ospaths, strutils, complex

type
    PyObject* = distinct pointer

    PyCFunction = proc(s, a: PyObject): PyObject {.cdecl.}

    PyMethodDef = object
        ml_name: cstring
        ml_meth: PyCFunction
        ml_flags: cint
        ml_doc: cstring

    PyMemberDef = object
        name: cstring
        typ: cint
        offset: Py_ssize_t
        flags: cint
        doc: cstring

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
    Newfunc = proc(typ: PyTypeObject, a, b: PyObject): PyObject {.cdecl.}
    Allocfunc = proc(typ: PyTypeObject, sz: Py_ssize_t): PyObject {.cdecl.}
    Freefunc = proc(p: pointer) {.cdecl.}
    Cmpfunc = proc(a, b: PyObject): cint {.cdecl.}

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

    PyTypeObject3 = ptr PyTypeObject3Obj
    PyTypeObject3Obj = object of PyObjectVarHeadObj
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
        tp_members:  ptr PyMemberDef
        tp_getset: pointer # ptr PyGetSetDef

        tp_base: PyTypeObject3
        tp_dict: PyObject

        tp_descr_get: Descrgetfunc
        tp_descr_set: Descrsetfunc
        tp_dictoffset: Py_ssize_t

        tp_init: Initproc
        tp_alloc: Allocfunc
        tp_new: Newfunc

        tp_free: Freefunc
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

    PyTypeObject2 = ptr PyTypeObject2Obj
    PyTypeObject2Obj = object of PyObjectVarHeadObj
        tp_name: cstring
        tp_basicsize, tp_itemsize: cint

        # Methods to implement standard operations
        tp_dealloc: Destructor
        tp_print: Printfunc

        tp_getattr: Getattrfunc
        tp_setattr: Setattrfunc
        tp_compare: Cmpfunc
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
        tp_weaklistoffset: clong

        # Iterators
        tp_iter: Getiterfunc
        tp_iternext: Iternextfunc

        # Attribute descriptor and subclassing stuff
        tp_methods: ptr PyMethodDef
        tp_members: ptr PyMemberDef
        tp_getset: pointer # ptr PyGetSetDef

        tp_base: PyTypeObject2
        tp_dict: PyObject

        tp_descr_get: Descrgetfunc
        tp_descr_set: Descrsetfunc
        tp_dictoffset: clong

        tp_init: Initproc
        tp_alloc: Allocfunc
        tp_new: Newfunc

        tp_free: Freefunc
        tp_is_gc: pointer # inquiry /* For PyObject_IS_GC */

        tp_bases: ptr PyObjectObj
        tp_mro: PyObject # method resolution order. array?
        tp_cache: PyObject # array?
        tp_subclasses: ptr PyObjectObj
        tp_weaklist: ptr PyObjectObj

    PyTypeObject = PyTypeObject3

    PyLib = ref object
        module: LibHandle

        Py_BuildValue*: proc(f: cstring): PyObject {.cdecl, varargs.}
        PyTuple_Size*: proc(f: PyObject): Py_ssize_t {.cdecl.}
        PyTuple_GetItem*: proc(f: PyObject, i: Py_ssize_t): PyObject {.cdecl.}

        Py_None*: PyObject
        PyType_Ready*: proc(f: PyTypeObject): cint {.cdecl.}
        PyType_GenericNew*: proc(f: PyTypeObject, a, b: PyObject): PyObject {.cdecl.}
        PyModule_AddObject*: proc(m: PyObject, n: cstring, o: PyObject): cint {.cdecl.}

        # PyList_Check*: proc(l: PyObject): cint {.cdecl.}
        PyList_New*: proc(size: Py_ssize_t): PyObject {.cdecl.}
        PyList_Size*: proc(l: PyObject): Py_ssize_t {.cdecl.}
        PyList_GetItem*: proc(l: PyObject, index: Py_ssize_t): PyObject {.cdecl.}
        PyList_SetItem*: proc(l: PyObject, index: Py_ssize_t, i: PyObject): cint {.cdecl.}

        PyLong_AsLongLong*: proc(l: PyObject): int64 {.cdecl.}
        PyFloat_AsDouble*: proc(l: PyObject): cdouble {.cdecl.}
        PyBool_FromLong*: proc(v: clong): PyObject {.cdecl.}

        PyComplex_AsCComplex*: proc(op: PyObject): Complex {.cdecl.}
        PyComplex_RealAsDouble*: proc(op: PyObject): cdouble {.cdecl.}
        PyComplex_ImagAsDouble*: proc(op: PyObject): cdouble {.cdecl.}

    PyNimObject = ref object {.inheritable.}
        py_extra_dont_use: PyObject_HEAD_EXTRA
        py_object: PyObjectObj

    PyNimObjectBaseToInheritFromForAnExportedType* = PyNimObject

var PyArg_ParseTuple*: proc(f: PyObject, fmt: cstring): cint {.cdecl, varargs.}

    #  PyBufferProcs contains bf_getcharbuffer
const Py_TPFLAGS_HAVE_GETCHARBUFFER  =(1 shl 0)

    #  PySequenceMethods contains sq_contains
const Py_TPFLAGS_HAVE_SEQUENCE_IN =(1 shl 1)

# This is here for backwards compatibility.  Extensions that use the old GC
# API will still compile but the objects will not be tracked by the GC.
#const Py_TPFLAGS_GC 0 #  used to be (1 shl 2) =

    #  PySequenceMethods and PyNumberMethods contain in-place operators
const Py_TPFLAGS_HAVE_INPLACEOPS =(1 shl 3)

    #  PyNumberMethods do their own coercion
const Py_TPFLAGS_CHECKTYPES =(1 shl 4)

    #  tp_richcompare is defined
const Py_TPFLAGS_HAVE_RICHCOMPARE =(1 shl 5)

    #  Objects which are weakly referencable if their tp_weaklistoffset is >0
const Py_TPFLAGS_HAVE_WEAKREFS =(1 shl 6)

    #  tp_iter is defined
const Py_TPFLAGS_HAVE_ITER =(1 shl 7)

    #  New members introduced by Python 2.2 exist
const Py_TPFLAGS_HAVE_CLASS =(1 shl 8)

    #  Set if the type object is dynamically allocated
const Py_TPFLAGS_HEAPTYPE =(1 shl 9)

    #  Set if the type allows subclassing
const Py_TPFLAGS_BASETYPE =(1 shl 10)

    #  Set if the type is 'ready' -- fully initialized
const Py_TPFLAGS_READY =(1 shl 12)

    #  Set while the type is being 'readied', to prevent recursive ready calls
const Py_TPFLAGS_READYING =(1 shl 13)

    #  Objects support garbage collection (see objimp.h)
const Py_TPFLAGS_HAVE_GC =(1 shl 14)

    #  These two bits are preserved for Stackless Python, next after this is 17

const Py_TPFLAGS_HAVE_STACKLESS_EXTENSION =0

    #  Objects support nb_index in PyNumberMethods
const Py_TPFLAGS_HAVE_INDEX =(1 shl 17)

    #  Objects support type attribute cache
const Py_TPFLAGS_HAVE_VERSION_TAG   =(1 shl 18)
const Py_TPFLAGS_VALID_VERSION_TAG  =(1 shl 19)

    #  Type is abstract and cannot be instantiated
const Py_TPFLAGS_IS_ABSTRACT =(1 shl 20)

    #  Has the new buffer protocol
const Py_TPFLAGS_HAVE_NEWBUFFER =(1 shl 21)

    #  These flags are used to determine if a type is a subclass.
const Py_TPFLAGS_INT_SUBCLASS         =(1 shl 23)
const Py_TPFLAGS_LONG_SUBCLASS        =(1 shl 24)
const Py_TPFLAGS_LIST_SUBCLASS        =(1 shl 25)
const Py_TPFLAGS_TUPLE_SUBCLASS       =(1 shl 26)
const Py_TPFLAGS_STRING_SUBCLASS      =(1 shl 27)
const Py_TPFLAGS_UNICODE_SUBCLASS     =(1 shl 28)
const Py_TPFLAGS_DICT_SUBCLASS        =(1 shl 29)
const Py_TPFLAGS_BASE_EXC_SUBCLASS    =(1 shl 30)
const Py_TPFLAGS_TYPE_SUBCLASS        =(1 shl 31)

const Py_TPFLAGS_DEFAULT_EXTERNAL = Py_TPFLAGS_HAVE_GETCHARBUFFER or
                     Py_TPFLAGS_HAVE_SEQUENCE_IN or
                     Py_TPFLAGS_HAVE_INPLACEOPS or
                     Py_TPFLAGS_HAVE_RICHCOMPARE or
                     Py_TPFLAGS_HAVE_WEAKREFS or
                     Py_TPFLAGS_HAVE_ITER or
                     Py_TPFLAGS_HAVE_CLASS or
                     Py_TPFLAGS_HAVE_STACKLESS_EXTENSION or
                     Py_TPFLAGS_HAVE_INDEX

const Py_TPFLAGS_DEFAULT_CORE = Py_TPFLAGS_DEFAULT_EXTERNAL or Py_TPFLAGS_HAVE_VERSION_TAG

proc isNil*(p: PyObject): bool {.borrow.}

var pyLib: PyLib

type
    PyModuleDesc = object
        name: cstring
        doc: cstring
        methods: seq[PyMethodDef]
        types: seq[PyTypeDesc]

    PyTypeDesc = object
        module: ptr PyModuleDesc
        name: cstring
        doc: cstring
        fullName: string
        newFunc: Newfunc
        methods: seq[PyMethodDef]
        members: seq[PyMemberDef]
        origSize: int

proc addMethod(m: var PyModuleDesc, name, doc: cstring, f: PyCFunction) =
    m.methods.add(PyMethodDef(ml_name: name, ml_meth: f, ml_flags: 1, ml_doc: doc))

proc newNimObjToPyObj(typ: PyTypeObject, o: PyNimObject): PyObject =
    # echo "New called"
    GC_ref(o)
    result = cast[PyObject](addr o.py_object)
    o.py_object.ob_type = typ
    o.py_object.ob_refcnt = 1

proc newPyNimObject[T](typ: PyTypeObject, args, kwds: PyObject): PyObject {.cdecl.} =
    newNimObjToPyObj(typ, T.new())

proc initPythonModuleDesc(m: var PyModuleDesc, name, doc: cstring) =
    m.name = name
    m.doc = doc
    m.methods = @[]
    m.types = @[]

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

proc toNim(p: PyObject, t: typedesc): t {.inline.} =
    result = cast[t](cast[uint](p) - uint(sizeof(PyObject_HEAD_EXTRA) + sizeof(pointer)))

proc incRef(p: PyObject) {.inline.} =
    inc p.to(PyObjectObj).ob_refcnt

when defined(windows):
    import winlean
    proc getModuleHandle(path: cstring): LibHandle {.
        importc: "GetModuleHandle", header: "<windows.h>", stdcall.}

    proc enumProcessModules(hProcess: HANDLE, lphModule: ptr Handle, cb: DWORD, cbNeeded: ptr DWORD): WINBOOL {.
        importc: "K32EnumProcessModules", dynlib: "kernel32", stdcall.}

    proc getModuleFileName(handle: Handle, buf: cstring, size: int32): int32 {.
        importc: "GetModuleFileNameA", dynlib: "kernel32", stdcall.}

    proc findPythonDLL(): string =
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
                    if fn.endsWith(".dll") and fn.find("\\python") == fn.len - suffixLen:
                        return fn
        raise newException(Exception, "Could not find pythonXX.dll")


proc initCommon(m: var PyModuleDesc) =
    if pyLib.isNil:
        pyLib.new()
        when defined(windows):
            pyLib.module = getModuleHandle(findPythonDLL())
        else:
            pyLib.module = loadLib()
        assert(not pyLib.module.isNil)

        if not (pyLib.module.symAddr("PyModule_Create2").isNil or
                pyLib.module.symAddr("Py_InitModule4_64").isNil or
                pyLib.module.symAddr("Py_InitModule4").isNil):
            traceRefs = true

        template load(v: untyped, name: cstring) =
            pyLib.v = cast[type(pyLib.v)](pyLib.module.symAddr(name))
            if pyLib.v.isNil:
                raise newException(Exception, "Symbol not loaded: " & $name)

        load Py_BuildValue, "_Py_BuildValue_SizeT"
        load PyTuple_Size, "PyTuple_Size"
        load PyTuple_GetItem, "PyTuple_GetItem"
        PyArg_ParseTuple = cast[type(PyArg_ParseTuple)](pyLib.module.symAddr("_PyArg_ParseTuple_SizeT"))
        if PyArg_ParseTuple.isNil:
            raise newException(Exception, "Symbol not loaded: " & "PyArg_ParseTuple")

        load Py_None, "_Py_NoneStruct"
        load PyType_Ready, "PyType_Ready"
        load PyType_GenericNew, "PyType_GenericNew"
        load PyModule_AddObject, "PyModule_AddObject"
        # load PyList_Check, "PyList_Check"
        load PyList_New, "PyList_New"
        load PyList_Size, "PyList_Size"
        load PyList_GetItem, "PyList_GetItem"
        load PyList_SetItem, "PyList_SetItem"
        load PyLong_AsLongLong, "PyLong_AsLongLong"
        load PyFloat_AsDouble, "PyFloat_AsDouble"
        load PyBool_FromLong, "PyBool_FromLong"

        pyLib.PyComplex_AsCComplex = cast[type(pyLib.PyComplex_AsCComplex)](pyLib.module.symAddr("PyComplex_AsCComplex"))
        if pyLib.PyComplex_AsCComplex.isNil:
            load PyComplex_RealAsDouble, "PyComplex_RealAsDouble"
            load PyComplex_ImagAsDouble, "PyComplex_ImagAsDouble"

    m.methods.add(PyMethodDef()) # Add sentinel

proc destructNimObj(o: PyObject) {.cdecl.} =
    let n = toNim(o, PyNimObject)
    GC_unref(n)
    # echo "Destruct called"

proc freeNimObj(p: pointer) {.cdecl.} =
    raise newException(Exception, "Internal pynim error. Free called on Nim object.")

proc initModuleTypes[PyTypeObj](p: PyObject, m: var PyModuleDesc) =
    for i in 0 ..< m.types.len:
        let typ = pyAlloc(sizeof(PyTypeObj))
        let ty = typ.to(PyTypeObj)
        ty.tp_name = m.types[i].fullName

        # Nim objects have an m_type* in front, we're stripping that away for python,
        # so we're telling python that the size is less by one pointer
        ty.tp_basicsize = m.types[i].origSize.cint - sizeof(pointer).cint
        ty.tp_flags = Py_TPFLAGS_DEFAULT_EXTERNAL
        ty.tp_doc = m.types[i].doc
        ty.tp_new = m.types[i].newFunc
        ty.tp_free = freeNimObj
        ty.tp_dealloc = destructNimObj

        discard pyLib.PyType_Ready(cast[PyTypeObject](typ))
        incRef(typ)
        discard pyLib.PyModule_AddObject(p, m.types[i].name, typ)

proc initModule2(m: var PyModuleDesc) {.inline.} =
    initCommon(m)
    const PYTHON_ABI_VERSION = 1013

    var Py_InitModule4: proc(name: cstring, methods: ptr PyMethodDef, doc: cstring, self: PyObject, apiver: cint): PyObject {.cdecl.}
    Py_InitModule4 = cast[type(Py_InitModule4)](pyLib.module.symAddr("Py_InitModule4"))
    if Py_InitModule4.isNil:
        Py_InitModule4 = cast[type(Py_InitModule4)](pyLib.module.symAddr("Py_InitModule4_64"))
    if not Py_InitModule4.isNil:
        let py = Py_InitModule4(m.name, addr m.methods[0], m.doc, nil, PYTHON_ABI_VERSION)
        initModuleTypes[PyTypeObject3Obj](py, m) # Why does PyTypeObject3Obj work here and PyTypeObject2Obj does not???

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
    PyModule_Create2 = cast[type(PyModule_Create2)](pyLib.module.symAddr("PyModule_Create2"))

    if PyModule_Create2.isNil:
        PyModule_Create2 = cast[type(PyModule_Create2)](pyLib.module.symAddr("PyModule_Create2TraceRefs"))

    if not PyModule_Create2.isNil:
        var pymod = pyAlloc(sizeof(PyModuleDef))
        initPyModule(pymod.to(PyModuleDef), m)
        result = PyModule_Create2(pymod, PYTHON_ABI_VERSION)
        initModuleTypes[PyTypeObject3Obj](result, m)

proc NimMain() {.importc.}

{.push stackTrace: off.}
template initNimIfNeeded() =
    if pyLib.isNil:
        NimMain()

proc initModuleAux2(m: var PyModuleDesc) =
    initNimIfNeeded()
    initModule2(m)

proc initModuleAux3(m: var PyModuleDesc): PyObject =
    initNimIfNeeded()
    initModule3(m)
{.pop.}

template declarePyModuleIfNeededAux(name: untyped) =
    when not declared(gPythonLocalModuleDesc):
        const nameStr = astToStr(name)

        var gPythonLocalModuleDesc {.inject.}: PyModuleDesc
        initPythonModuleDesc(gPythonLocalModuleDesc, nameStr, nil)
        {.push stackTrace: off.}
        proc `py2init name`() {.exportc: "init" & nameStr, dynlib.} =
            initModuleAux2(gPythonLocalModuleDesc)

        proc `py3init name`(): PyObject {.exportc: "PyInit_" & nameStr, dynlib.} =
            initModuleAux3(gPythonLocalModuleDesc)
        {.pop.}

macro declarePyModuleIfNeededAuxMacro(modulename: static[string]): typed =
    let modulename = modulename.splitFile.name
    result = newCall(bindSym("declarePyModuleIfNeededAux"), newIdentNode(modulename))

template declarePyModuleIfNeeded() =
    declarePyModuleIfNeededAuxMacro(instantiationInfo(0).filename)

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
template pySignatureForType(t: typedesc[Complex]): string = "D"

proc pyObjToNim[T: int|int32|int64|int16|uint32|uint64|uint16|uint](o: PyObject, r: var T) {.inline.} =
    r = T(pyLib.PyLong_AsLongLong(o))

proc pyObjToNim[T: float|float32|float64](o: PyObject, r: var T) {.inline.} =
    r = T(pyLib.PyFloat_AsDouble(o))

proc pyObjToNim(o: PyObject; s: var Complex) =
    if unlikely pyLib.PyComplex_AsCComplex.isNil:
        s.re = pyLib.PyComplex_RealAsDouble(o)
        s.im = pyLib.PyComplex_ImagAsDouble(o)
    else:
        s = pyLib.PyComplex_AsCComplex(o)

proc pyObjToNim[T](o: PyObject, s: var seq[T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(pyLib.PyList_Size(o))
    assert(sz >= 0)
    s = newSeq[T](sz)
    for i in 0 ..< sz:
        pyObjToNim(pyLib.PyList_GetItem(o, i), s[i])

proc pyObjToNim[T, I](o: PyObject, s: var array[I, T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(pyLib.PyList_Size(o))
    assert(sz == s.len)
    for i in 0 ..< sz:
        pyObjToNim(pyLib.PyList_GetItem(o, i), s[i])

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
    pyLib.Py_BuildValue("s#", cs, ln)

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
        incRef(pyLib.Py_None)
        pyLib.Py_None
    elif T is string:
        strToPyObject(v)
    elif T is int32:
        pyLib.Py_BuildValue("i", v)
    elif T is int64:
        pyLib.Py_BuildValue("L", v)
    elif T is int:
        when sizeof(int) == sizeof(int32):
            pyLib.Py_BuildValue("i", v)
        elif sizeof(int) == sizeof(int64):
            pyLib.Py_BuildValue("L", v)
        else:
            {.error: "Unkown int size".}
    elif T is int8:
        pyLib.Py_BuildValue("b", v)
    elif T is uint8:
        pyLib.Py_BuildValue("B", v)
    elif T is int32:
        pyLib.Py_BuildValue("i", v)
    elif T is uint32:
        pyLib.Py_BuildValue("I", v)
    elif T is int16:
        pyLib.Py_BuildValue("h", v)
    elif T is uint16:
        pyLib.Py_BuildValue("H", v)
    elif T is int64:
        pyLib.Py_BuildValue("L", v)
    elif T is uint64:
        pyLib.Py_BuildValue("K", v)
    elif T is float32 | float | float64:
        pyLib.Py_BuildValue("d", float64(v))
    elif T is seq|array:
        nimArrToPy(v)
    elif T is bool:
        pyLib.PyBool_FromLong(clong(v))
    elif T is Complex:
        var c = v
        pyLib.Py_BuildValue("D", addr c)
    else:
        {.error: "Unkown return type".}

proc nimArrToPy[T](s: openarray[T]): PyObject =
    let sz = s.len
    result = pyLib.PyList_New(sz)
    for i in 0 ..< sz:
        let o = nimValueToPy(s[i])
        discard pyLib.PyList_SetItem(result, i, o)

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

proc exportProc(prc: NimNode, modulename, procName: string, wrap: bool): NimNode =
    let modulename = modulename.splitFile.name

    var comment: NimNode
    if prc.body.kind == nnkStmtList and prc.body.len != 0 and prc.body[0].kind == nnkCommentStmt:
        comment = newLit($prc.body[0])
    else:
        comment = newNilLit()

    if not wrap:
        prc.addPragma(newIdentNode("cdecl"))

    result = newStmtList(prc)

    var procIdent = prc.name
    var procName = procName
    if procName.isNil:
        procName = $procIdent
    if wrap:
        procIdent = newIdentNode($procIdent & "Py_wrapper")
        result.add(makeWrapper(procIdent, prc))

    result.add(newCall(bindSym"addMethod", newIdentNode("gPythonLocalModuleDesc"), newLit(procName), comment, procIdent))
    # echo "procname: ", procName
    # echo repr result

macro exportpyAux(prc: untyped, modulename, procName: static[string], wrap: static[bool]): untyped =
    exportProc(prc, modulename, procName, wrap)

template exportpyAuxAux(prc: untyped{nkProcDef}, procName: static[string]) =
    declarePyModuleIfNeeded()
    exportpyAux(prc, instantiationInfo().filename, procName, true)

template exportpyraw*(prc: untyped) =
    declarePyModuleIfNeeded()
    exportpyAux(prc, instantiationInfo().filename, nil, false)

macro exportpy*(nameOrProc: untyped, maybeProc: untyped = nil): untyped =
    var procDef: NimNode
    var procName: string
    if maybeProc.kind == nnkNilLit:
        procDef = nameOrProc
        procName = $procDef.name
    else:
        procDef = maybeProc
        procName = $nameOrProc

    expectKind(procDef, nnkProcDef)
    result = newCall(bindSym"exportpyAuxAux", procDef, newLit(procName))

template addType(m: var PyModuleDesc, T: typed) =
    block:
        const name = astToStr(T)
        const cname: cstring = name
        m.types.setLen(m.types.len + 1)
        m.types[^1].name = cname
        m.types[^1].doc = "TestType docs..."
        m.types[^1].newFunc = newPyNimObject[T]
        var t: T
        m.types[^1].origSize = sizeof(t[])
        m.types[^1].fullName = $m.name & "." & name

template pyexportTypeExperimental*(T: typed) =
    declarePyModuleIfNeeded()
    addType(gPythonLocalModuleDesc, T)
