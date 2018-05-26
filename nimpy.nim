import dynlib, macros, ospaths, strutils, complex

type
    PyObject* = ref object
        rawPyObj: PPyObject

    PPyObject* = distinct pointer

    PyCFunction = proc(s, a: PPyObject): PPyObject {.cdecl.}

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
        m_init: proc(): PPyObject {.cdecl.}
        m_index: Py_ssize_t
        m_copy: PPyObject

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
        obj: PPyObject
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

    Destructor = proc(o: PPyObject) {.cdecl.}
    Printfunc = proc(o: PPyObject, f: File, c: cint): cint {.cdecl}
    Getattrfunc = proc(o: PPyObject, a: cstring): PPyObject {.cdecl.}
    Getattrofunc = proc(o, a: PPyObject): PPyObject {.cdecl.}
    Setattrfunc = proc(o: PPyObject, a: cstring, at: PPyObject): cint {.cdecl.}
    Setattrofunc = proc(o, a, at: PPyObject): cint {.cdecl.}
    Reprfunc = proc(o: PPyObject): PPyObject {.cdecl.}
    Richcmpfunc = proc(a, b: PPyObject, c: cint): PPyObject {.cdecl.}
    Getiterfunc = proc(a: PPyObject): PPyObject {.cdecl.}
    Iternextfunc = proc(a: PPyObject): PPyObject {.cdecl.}
    Descrgetfunc = proc(a, b, c: PPyObject): PPyObject {.cdecl.}
    Descrsetfunc = proc(a, b, c: PPyObject): cint {.cdecl.}
    Initproc = proc(a, b, c: PPyObject): cint {.cdecl.}
    Newfunc = proc(typ: PyTypeObject, a, b: PPyObject): PPyObject {.cdecl.}
    Allocfunc = proc(typ: PyTypeObject, sz: Py_ssize_t): PPyObject {.cdecl.}
    Freefunc = proc(p: pointer) {.cdecl.}
    Cmpfunc = proc(a, b: PPyObject): cint {.cdecl.}

    # 3
    # typedef PPyObject *(*getattrfunc)(PPyObject *, char *);
    # typedef PPyObject *(*getattrofunc)(PPyObject *, PPyObject *);
    # typedef int (*setattrfunc)(PPyObject *, char *, PPyObject *);
    # typedef int (*setattrofunc)(PPyObject *, PPyObject *, PPyObject *);
    # typedef PPyObject *(*reprfunc)(PPyObject *);
    # typedef Py_hash_t (*hashfunc)(PPyObject *);
    # typedef PPyObject *(*richcmpfunc) (PPyObject *, PPyObject *, int);
    # typedef PPyObject *(*getiterfunc) (PPyObject *);
    # typedef PPyObject *(*iternextfunc) (PPyObject *);
    # typedef PPyObject *(*descrgetfunc) (PPyObject *, PPyObject *, PPyObject *);
    # typedef int (*descrsetfunc) (PPyObject *, PPyObject *, PPyObject *);
    # typedef int (*initproc)(PPyObject *, PPyObject *, PPyObject *);
    # typedef PPyObject *(*newfunc)(struct _typeobject *, PPyObject *, PPyObject *);
    # typedef PPyObject *(*allocfunc)(struct _typeobject *, Py_ssize_t);

    # 2
    # typedef PPyObject *(*getattrfunc)(PPyObject *, char *);
    # typedef PPyObject *(*getattrofunc)(PPyObject *, PPyObject *);
    # typedef int (*setattrfunc)(PPyObject *, char *, PPyObject *);
    # typedef int (*setattrofunc)(PPyObject *, PPyObject *, PPyObject *);
    # typedef int (*cmpfunc)(PPyObject *, PPyObject *);
    # typedef PPyObject *(*reprfunc)(PPyObject *);
    # typedef long (*hashfunc)(PPyObject *);
    # typedef PPyObject *(*richcmpfunc) (PPyObject *, PPyObject *, int);
    # typedef PPyObject *(*getiterfunc) (PPyObject *);
    # typedef PPyObject *(*iternextfunc) (PPyObject *);
    # typedef PPyObject *(*descrgetfunc) (PPyObject *, PPyObject *, PPyObject *);
    # typedef int (*descrsetfunc) (PPyObject *, PPyObject *, PPyObject *);
    # typedef int (*initproc)(PPyObject *, PPyObject *, PPyObject *);
    # typedef PPyObject *(*newfunc)(struct _typeobject *, PPyObject *, PPyObject *);
    # typedef PPyObject *(*allocfunc)(struct _typeobject *, Py_ssize_t);

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
        tp_dict: PPyObject

        tp_descr_get: Descrgetfunc
        tp_descr_set: Descrsetfunc
        tp_dictoffset: Py_ssize_t

        tp_init: Initproc
        tp_alloc: Allocfunc
        tp_new: Newfunc

        tp_free: Freefunc
        tp_is_gc: pointer # inquiry /* For PyObject_IS_GC */

        tp_bases: ptr PyObjectObj
        tp_mro: PPyObject # method resolution order. array?
        tp_cache: PPyObject # array?
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
        tp_dict: PPyObject

        tp_descr_get: Descrgetfunc
        tp_descr_set: Descrsetfunc
        tp_dictoffset: clong

        tp_init: Initproc
        tp_alloc: Allocfunc
        tp_new: Newfunc

        tp_free: Freefunc
        tp_is_gc: pointer # inquiry /* For PyObject_IS_GC */

        tp_bases: ptr PyObjectObj
        tp_mro: PPyObject # method resolution order. array?
        tp_cache: PPyObject # array?
        tp_subclasses: ptr PyObjectObj
        tp_weaklist: ptr PyObjectObj

    PyTypeObject = PyTypeObject3

    PyLib = ref object
        module: LibHandle

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

        PyLong_AsLongLong*: proc(l: PPyObject): int64 {.cdecl.}
        PyFloat_AsDouble*: proc(l: PPyObject): cdouble {.cdecl.}
        PyBool_FromLong*: proc(v: clong): PPyObject {.cdecl.}

        PyComplex_AsCComplex*: proc(op: PPyObject): Complex {.cdecl.}
        PyComplex_RealAsDouble*: proc(op: PPyObject): cdouble {.cdecl.}
        PyComplex_ImagAsDouble*: proc(op: PPyObject): cdouble {.cdecl.}

        PyUnicode_AsUTF8String*: proc(o: PPyObject): PPyObject {.cdecl.}
        PyBytes_AsStringAndSize*: proc(o: PPyObject, s: ptr ptr char, len: ptr Py_ssize_t): cint {.cdecl.}

        PyDict_Type*: PyTypeObject
        PyDict_GetItemString*: proc(o: PPyObject, k: cstring): PPyObject {.cdecl.}
        PyDict_SetItemString*: proc(o: PPyObject, k: cstring, v: PPyObject): cint {.cdecl.}

        PyDealloc*: proc(o: PPyObject) {.nimcall.}

        PyErr_Clear*: proc() {.cdecl.}
        PyErr_SetString*: proc(o: PPyObject, s: cstring) {.cdecl.}
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

    PyNimObject = ref object {.inheritable.}
        py_extra_dont_use: PyObject_HEAD_EXTRA
        py_object: PyObjectObj

    PyNimObjectBaseToInheritFromForAnExportedType* = PyNimObject

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

proc isNil*(p: PPyObject): bool {.borrow.}

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

proc newNimObjToPyObj(typ: PyTypeObject, o: PyNimObject): PPyObject =
    # echo "New called"
    GC_ref(o)
    result = cast[PPyObject](addr o.py_object)
    o.py_object.ob_type = typ
    o.py_object.ob_refcnt = 1

proc newPyNimObject[T](typ: PyTypeObject, args, kwds: PPyObject): PPyObject {.cdecl.} =
    newNimObjToPyObj(typ, T.new())

proc initPythonModuleDesc(m: var PyModuleDesc, name, doc: cstring) =
    m.name = name
    m.doc = doc
    m.methods = @[]
    m.types = @[]

var traceRefs: bool

proc pyAlloc(sz: int): PPyObject =
    var sz = sz
    if traceRefs:
        sz += sizeof(PyObject_HEAD_EXTRA)
    result = cast[PPyObject](alloc0(sz))

proc to(p: PPyObject, t: typedesc): ptr t {.inline.} =
    if traceRefs:
        result = cast[ptr t](cast[uint](p) + sizeof(PyObject_HEAD_EXTRA).uint)
    else:
        result = cast[ptr t](p)

proc toNim(p: PPyObject, t: typedesc): t {.inline.} =
    result = cast[t](cast[uint](p) - uint(sizeof(PyObject_HEAD_EXTRA) + sizeof(pointer)))

proc incRef(p: PPyObject) {.inline.} =
    inc p.to(PyObjectObj).ob_refcnt

proc decRef(p: PPyObject) {.inline.} =
    let o = p.to(PyObjectObj)
    dec o.ob_refcnt
    if o.ob_refcnt == 0:
        pyLib.PyDealloc(p)

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


proc deallocPythonObj[TypeObjectType](p: PPyObject) =
    let ob = p.to(PyObjectObj)
    let t = cast[TypeObjectType](ob.ob_type)
    t.tp_dealloc(cast[PPyObject](p))

proc symNotLoadedErr(s: cstring) =
    raise newException(Exception, "Symbol not loaded: " & $s)

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

        template maybeLoad(v: untyped, name: cstring) =
            pyLib.v = cast[type(pyLib.v)](pyLib.module.symAddr(name))

        template load(v: untyped, name: cstring) =
            maybeLoad(v, name)
            if pyLib.v.isNil:
                symNotLoadedErr(name)

        template maybeLoad(v: untyped) = maybeLoad(v, astToStr(v))
        template load(v: untyped) = load(v, astToStr(v))

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

        load PyLong_AsLongLong
        load PyFloat_AsDouble
        load PyBool_FromLong

        maybeLoad PyComplex_AsCComplex
        if pyLib.PyComplex_AsCComplex.isNil:
            load PyComplex_RealAsDouble
            load PyComplex_ImagAsDouble

        maybeLoad PyUnicode_AsUTF8String
        if pyLib.PyUnicode_AsUTF8String.isNil:
            maybeLoad PyUnicode_AsUTF8String, "PyUnicodeUCS4_AsUTF8String"
            if pyLib.PyUnicode_AsUTF8String.isNil:
                load PyUnicode_AsUTF8String, "PyUnicodeUCS2_AsUTF8String"

        pyLib.pythonVersion = 3

        maybeLoad PyBytes_AsStringAndSize
        if pyLib.PyBytes_AsStringAndSize.isNil:
            load PyBytes_AsStringAndSize, "PyString_AsStringAndSize"
            pyLib.pythonVersion = 2

        load PyDict_Type
        load PyDict_GetItemString
        load PyDict_SetItemString

        if pyLib.pythonVersion == 3:
            pyLib.PyDealloc = deallocPythonObj[PyTypeObject3]
        else:
            pyLib.PyDealloc = deallocPythonObj[PyTypeObject3] # Why does PyTypeObject3Obj work here and PyTypeObject2Obj does not???

        load PyErr_Clear
        load PyErr_SetString
        load PyExc_TypeError

        pyLib.PyExc_TypeError = cast[ptr PPyObject](pyLib.PyExc_TypeError)[]

        load PyCapsule_New
        load PyCapsule_GetPointer

        load PyImport_ImportModule
        load PyEval_GetBuiltins
        load PyEval_GetGlobals
        load PyEval_GetLocals

        when not defined(release):
            load PyErr_Print

    m.methods.add(PyMethodDef()) # Add sentinel

proc destructNimObj(o: PPyObject) {.cdecl.} =
    let n = toNim(o, PyNimObject)
    GC_unref(n)
    # echo "Destruct called"

proc freeNimObj(p: pointer) {.cdecl.} =
    raise newException(Exception, "Internal pynim error. Free called on Nim object.")

proc initModuleTypes[PyTypeObj](p: PPyObject, m: var PyModuleDesc) =
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

proc initModule2(m: var PyModuleDesc) =
    initCommon(m)
    const PYTHON_ABI_VERSION = 1013

    var Py_InitModule4: proc(name: cstring, methods: ptr PyMethodDef, doc: cstring, self: PPyObject, apiver: cint): PPyObject {.cdecl.}
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

proc initModule3(m: var PyModuleDesc): PPyObject =
    initCommon(m)
    const PYTHON_ABI_VERSION = 3
    var PyModule_Create2: proc(m: PPyObject, apiver: cint): PPyObject {.cdecl.}
    PyModule_Create2 = cast[type(PyModule_Create2)](pyLib.module.symAddr("PyModule_Create2"))

    if PyModule_Create2.isNil:
        PyModule_Create2 = cast[type(PyModule_Create2)](pyLib.module.symAddr("PyModule_Create2TraceRefs"))

    if not PyModule_Create2.isNil:
        var pymod = pyAlloc(sizeof(PyModuleDef))
        initPyModule(pymod.to(PyModuleDef), m)
        result = PyModule_Create2(pymod, PYTHON_ABI_VERSION)
        initModuleTypes[PyTypeObject3Obj](result, m)

template declarePyModuleIfNeededAux(name: untyped) =
    when not declared(gPythonLocalModuleDesc):
        const nameStr = astToStr(name)

        var gPythonLocalModuleDesc {.inject.}: PyModuleDesc
        initPythonModuleDesc(gPythonLocalModuleDesc, nameStr, nil)
        {.push stackTrace: off.}
        proc `py2init name`() {.exportc: "init" & nameStr, dynlib.} =
            initModule2(gPythonLocalModuleDesc)

        proc `py3init name`(): PPyObject {.exportc: "PyInit_" & nameStr, dynlib.} =
            initModule3(gPythonLocalModuleDesc)
        {.pop.}

macro declarePyModuleIfNeededAuxMacro(modulename: static[string]): typed =
    let modulename = modulename.splitFile.name
    result = newCall(bindSym("declarePyModuleIfNeededAux"), newIdentNode(modulename))

template declarePyModuleIfNeeded() =
    declarePyModuleIfNeededAuxMacro(instantiationInfo(0).filename)

################################################################################
################################################################################
################################################################################

proc toString*(b: Py_buffer): string =
    if not b.buf.isNil:
        let ln = b.len
        result = newString(ln)
        if ln != 0:
            copyMem(addr result[0], b.buf, ln)

proc pyObjToNimSeq[T](o: PPyObject, v: var seq[T])
proc pyObjToNimArray[T, I](o: PPyObject, s: var array[I, T])
proc pyObjToNimStr(o: PPyObject, v: var string) =
    var s: ptr char
    var l: Py_ssize_t
    var b: PPyObject

    if pyLib.PyBytes_AsStringAndSize(o, addr s, addr l) != 0:
        # TODO: This requires more elaborate type checking to avoid raising and clearing errors
        pyLib.PyErr_Clear()
        # pyLib.PyErr_Print()

        b = pyLib.PyUnicode_AsUTF8String(o)
        if b.isNil:
            # pyLib.PyErr_Print()
            raise newException(Exception, "Can't convert python obj to string")

        if pyLib.PyBytes_AsStringAndSize(b, addr s, addr l) != 0:
            decRef b
            raise newException(Exception, "Can't convert python obj to string")

    v = newString(l)
    if l != 0:
        copyMem(addr v[0], s, l)

    if not b.isNil:
        decRef b

proc unknownTypeCompileError() {.inline.} =
    # This function never compiles, it is needed to see somewhat informative
    # compile time error
    discard

proc pyObjToNim[T](o: PPyObject, v: var T)

proc strToPyObject(s: string): PPyObject {.inline.} =
    var cs: cstring
    var ln: cint
    if not s.isNil:
        cs = s
        ln = cint(s.xlen)
    pyLib.Py_BuildValue("s#", cs, ln)

proc pyObjToNimObj(o: PPyObject, vv: var object) =
    for k, v in fieldPairs(vv):
        let f = pyLib.PyDict_GetItemString(o, k)
        pyObjToNim(f, v)
        # No DECREF here. PyDict_GetItemString returns a boorowed ref.

proc finalizePyObject(o: PyObject) =
    decRef o.rawPyObj

proc newPyObjectConsumingRef(o: PPyObject): PyObject =
    result.new(finalizePyObject)
    result.rawPyObj = o

proc newPyObject(o: PPyObject): PyObject =
    incRef o
    newPyObjectConsumingRef(o)

proc pyObjToNim[T](o: PPyObject, v: var T) =
    when T is int|int32|int64|int16|uint32|uint64|uint16|uint8|int8:
        v = T(pyLib.PyLong_AsLongLong(o))
    elif T is float|float32|float64:
        v = T(pyLib.PyFloat_AsDouble(o))
    elif T is bool:
        v = bool(pyLib.PyObject_IsTrue(o))
    elif T is PPyObject:
        v = o
    elif T is PyObject:
        v = newPyObject(o)
    elif T is Complex:
        if unlikely pyLib.PyComplex_AsCComplex.isNil:
            v.re = pyLib.PyComplex_RealAsDouble(o)
            v.im = pyLib.PyComplex_ImagAsDouble(o)
        else:
            v = pyLib.PyComplex_AsCComplex(o)
    elif T is string:
        pyObjToNimStr(o, v)
    elif T is seq:
        pyObjToNimSeq(o, v)
    elif T is array:
        pyObjToNimArray(o, v)
    elif T is ref:
        if cast[pointer](o) == cast[pointer](pyLib.Py_None):
            v = nil
        else:
            v = cast[T](pyLib.PyCapsule_GetPointer(o, nil))
    elif T is object:
        pyObjToNimObj(o, v)
    else:
        unknownTypeCompileError(v)

proc pyObjToNimSeq[T](o: PPyObject, v: var seq[T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(pyLib.PyList_Size(o))
    assert(sz >= 0)
    v = newSeq[T](sz)
    for i in 0 ..< sz:
        pyObjToNim(pyLib.PyList_GetItem(o, i), v[i])
        # PyList_GetItem # No DECREF. Returns borrowed ref.

proc pyObjToNimArray[T, I](o: PPyObject, s: var array[I, T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(pyLib.PyList_Size(o))
    assert(sz == s.len)
    for i in 0 ..< sz:
        pyObjToNim(pyLib.PyList_GetItem(o, i), s[i])
        # PyList_GetItem # No DECREF. Returns borrowed ref.

iterator arguments(prc: NimNode): tuple[idx: int, name, typ, default: NimNode] =
    let p = prc.params
    var iParam = 0
    for i in 1 ..< p.len:
        let pp = p[i]
        for j in 0 .. pp.len - 3:
            yield (iParam, pp[j], pp[^2], pp[^1])
            inc iParam

proc nimArrToPy[T](s: openarray[T]): PPyObject
proc nimObjToPy[T](o: T): PPyObject

proc refCapsuleDestructor(c: PPyObject) {.cdecl.} =
    let o = pyLib.PyCapsule_GetPointer(c, nil)
    GC_unref(cast[ref int](o))

proc nimValueToPy[T](v: T): PPyObject {.inline.} =
    when T is void:
        incRef(pyLib.Py_None)
        pyLib.Py_None
    elif T is PPyObject:
        v
    elif T is PyObject:
        incRef v.rawPyObj
        v.rawPyObj
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
    elif T is ref:
        if v.isNil:
            incRef(pyLib.Py_None)
            pyLib.Py_None
        else:
            GC_ref(v)
            pyLib.PyCapsule_New(cast[pointer](v), nil, refCapsuleDestructor)
    elif T is bool:
        pyLib.PyBool_FromLong(clong(v))
    elif T is Complex:
        pyLib.Py_BuildValue("D", unsafeAddr v)
    elif T is object:
        nimObjToPy(v)
    else:
        unknownTypeCompileError(v)

proc nimArrToPy[T](s: openarray[T]): PPyObject =
    let sz = s.len
    result = pyLib.PyList_New(sz)
    for i in 0 ..< sz:
        let o = nimValueToPy(s[i])
        discard pyLib.PyList_SetItem(result, i, o)

proc PyObject_CallObject(o: PPyObject): PPyObject =
    let args = pyLib.PyTuple_New(0)
    result = pyLib.PyObject_Call(o, args, nil)
    decRef args

proc cannotSerializeErr(k: string) =
    raise newException(Exception, "Could not serialize object key: " & k)

proc nimObjToPy[T](o: T): PPyObject =
    result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
    for k, v in fieldPairs(o):
        let vv = nimValueToPy(v)
        let ret = pyLib.PyDict_SetItemString(result, k, vv)
        decRef vv
        if ret != 0:
            cannotSerializeErr(k)

proc parseArg[T](argTuple: PPyObject, argIdx: int, result: var T) =
    pyObjToNim(pyLib.PyTuple_GetItem(argTuple, argIdx), result)

proc verifyArgs(argTuple: PPyObject, argsLen: int, funcName: string): bool =
    let sz = pyLib.PyTuple_Size(argTuple)
    result = sz == argsLen
    if not result:
        pyLib.PyErr_SetString(pyLib.PyExc_TypeError, funcName & "() takes exactly " & $argsLen & " arguments (" & $sz & " given)")

template seqTypeForOpenarrayType[T](t: type openarray[T]): typedesc = seq[T]
template valueTypeForArgType(t: typedesc): typedesc =
    when t is openarray:
        seqTypeForOpenarrayType(t)
    else:
        t

proc updateStackBottom() {.inline.} =
    when declared(GC_setStackBottom):
        var a: int
        GC_setStackBottom(addr a)

proc makeWrapper(originalName: string, name, prc: NimNode): NimNode =
    let selfIdent = newIdentNode("self")
    let argsIdent = newIdentNode("args")

    result = newProc(name, params = [bindSym"PPyObject", newIdentDefs(selfIdent, bindSym"PPyObject"), newIdentDefs(argsIdent, bindSym"PPyObject")])
    result.addPragma(newIdentNode("cdecl"))
    result.body = newStmtList()

    let pyValueVarSection = newNimNode(nnkVarSection)
    result.body.add(pyValueVarSection)

    let parseArgsStmts = newNimNode(nnkStmtList)
    let origCall = newCall(prc.name)

    var numArgs = 0
    for a in prc.arguments:
        let argIdent = newIdentNode("arg" & $a.idx & $a.name)
        pyValueVarSection.add(newIdentDefs(argIdent, newCall(bindSym"valueTypeForArgType", a.typ)))
        parseArgsStmts.add(newCall(bindSym"parseArg", argsIdent, newLit(a.idx), argIdent))
        origCall.add(argIdent)
        inc numArgs

    let argsLen = newLit(numArgs)
    let nameLit = newLit(originalName)
    result.body.add quote do:
        updateStackBottom()
        if verifyArgs(`argsIdent`, `argsLen`, `nameLit`):
            `parseArgsStmts`
            return nimValueToPy(`origCall`)

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
        result.add(makeWrapper(procName, procIdent, prc))

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

# template exportpyIdent(i: typed, exportName: static[string]) =
#     discard

macro exportpy*(nameOrProc: untyped, maybeProc: untyped = nil): untyped =
    var procDef: NimNode
    var procName: string
    if maybeProc.kind == nnkNilLit:
        procDef = nameOrProc
        procName = $procDef.name
    else:
        procDef = maybeProc
        procName = $nameOrProc

    # if procDef.kind in {nnkIdent, nnkSym}:
    #     result = newCall(bindSym"exportpyIdent", procDef, newLit(procName))
    # else:
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


################################################################################
################################################################################
################################################################################
# Calling functions

template toPyObjectArgument*[T](v: T): PPyObject =
    # Don't use this directly!
    nimValueToPy(v)

proc to*(v: PyObject, T: typedesc): T {.inline.} =
    pyObjToNim(v.rawPyObj, result)

proc callMethodAux(o: PPyObject, name: cstring, args: openarray[PPyObject]): PPyObject =
    let callable = pyLib.PyObject_GetAttrString(o, name)
    if callable.isNil:
        raise newException(Exception, "No callable attribute: " & $name)

    let argTuple = pyLib.PyTuple_New(args.len)
    for i, v in args:
        discard pyLib.PyTuple_SetItem(argTuple, i, v)

    result = pyLib.PyObject_Call(callable, argTuple, nil)
    decRef argTuple
    decRef callable

proc callMethod*(o: PyObject, name: cstring, args: varargs[PPyObject, toPyObjectArgument]): PyObject {.inline.} =
    newPyObjectConsumingRef(callMethodAux(o.rawPyObj, name, args))

proc callMethod*(o: PyObject, ResultType: typedesc, name: cstring, args: varargs[PPyObject, toPyObjectArgument]): ResultType {.inline.} =
    let res = callMethodAux(o.rawPyObj, name, args)
    pyObjToNim(res, result)
    decRef res

template `.()`*(o: PyObject, field: untyped, args: varargs[PPyObject, toPyObjectArgument]): PyObject =
    callMethod(o, astToStr(field), args)

proc pyImport*(moduleName: cstring): PyObject =
    newPyObjectConsumingRef(pyLib.PyImport_ImportModule(moduleName))

proc pyBuiltins*(): PyObject = newPyObject(pyLib.PyEval_GetBuiltins())
proc pyGlobals*(): PyObject = newPyObject(pyLib.PyEval_GetGlobals())
proc pyLocals*(): PyObject = newPyObject(pyLib.PyEval_GetLocals())

proc dir*(v: PyObject): seq[string] =
    let lst = pyLib.PyObject_Dir(v.rawPyObj)
    pyObjToNim(lst, result)
    decRef lst

proc pyBuiltinsModule*(): PyObject =
    if pyLib.pythonVersion == 3:
        pyImport("builtins")
    else:
        pyImport("__builtin__")
