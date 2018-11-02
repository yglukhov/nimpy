import dynlib, macros, ospaths, strutils, complex, strutils, sequtils, typetraits, tables, json,
    nimpy/[py_types, py_utils]

import nimpy/py_lib as lib

type
    PyObject* = ref object
        rawPyObj: PPyObject

    PyNimObject = ref object {.inheritable.}
        py_extra_dont_use: PyObject_HEAD_EXTRA
        py_object: PyObjectObj

    PyNimObjectBaseToInheritFromForAnExportedType* = PyNimObject

const
    #  PyBufferProcs contains bf_getcharbuffer
    Py_TPFLAGS_HAVE_GETCHARBUFFER  =(1 shl 0)

    #  PySequenceMethods contains sq_contains
    Py_TPFLAGS_HAVE_SEQUENCE_IN =(1 shl 1)

# This is here for backwards compatibility.  Extensions that use the old GC
# API will still compile but the objects will not be tracked by the GC.
#    Py_TPFLAGS_GC 0 #  used to be (1 shl 2) =

    #  PySequenceMethods and PyNumberMethods contain in-place operators
    Py_TPFLAGS_HAVE_INPLACEOPS =(1 shl 3)

    #  PyNumberMethods do their own coercion
    Py_TPFLAGS_CHECKTYPES =(1 shl 4)

    #  tp_richcompare is defined
    Py_TPFLAGS_HAVE_RICHCOMPARE =(1 shl 5)

    #  Objects which are weakly referencable if their tp_weaklistoffset is >0
    Py_TPFLAGS_HAVE_WEAKREFS =(1 shl 6)

    #  tp_iter is defined
    Py_TPFLAGS_HAVE_ITER =(1 shl 7)

    #  New members introduced by Python 2.2 exist
    Py_TPFLAGS_HAVE_CLASS =(1 shl 8)

    #  Set if the type object is dynamically allocated
    Py_TPFLAGS_HEAPTYPE =(1 shl 9)

    #  Set if the type allows subclassing
    Py_TPFLAGS_BASETYPE =(1 shl 10)

    #  Set if the type is 'ready' -- fully initialized
    Py_TPFLAGS_READY =(1 shl 12)

    #  Set while the type is being 'readied', to prevent recursive ready calls
    Py_TPFLAGS_READYING =(1 shl 13)

    #  Objects support garbage collection (see objimp.h)
    Py_TPFLAGS_HAVE_GC =(1 shl 14)

    #  These two bits are preserved for Stackless Python, next after this is 17

    Py_TPFLAGS_HAVE_STACKLESS_EXTENSION =0

    #  Objects support nb_index in PyNumberMethods
    Py_TPFLAGS_HAVE_INDEX =(1 shl 17)

    #  Objects support type attribute cache
    Py_TPFLAGS_HAVE_VERSION_TAG   =(1 shl 18)
    Py_TPFLAGS_VALID_VERSION_TAG  =(1 shl 19)

    #  Type is abstract and cannot be instantiated
    Py_TPFLAGS_IS_ABSTRACT =(1 shl 20)

    #  Has the new buffer protocol
    Py_TPFLAGS_HAVE_NEWBUFFER =(1 shl 21)

    #  These flags are used to determine if a type is a subclass.
    Py_TPFLAGS_INT_SUBCLASS         =(1 shl 23)
    Py_TPFLAGS_LONG_SUBCLASS        =(1 shl 24)
    Py_TPFLAGS_LIST_SUBCLASS        =(1 shl 25)
    Py_TPFLAGS_TUPLE_SUBCLASS       =(1 shl 26)
    Py_TPFLAGS_STRING_SUBCLASS      =(1 shl 27)
    Py_TPFLAGS_UNICODE_SUBCLASS     =(1 shl 28)
    Py_TPFLAGS_DICT_SUBCLASS        =(1 shl 29)
    Py_TPFLAGS_BASE_EXC_SUBCLASS    =(1 shl 30)
    Py_TPFLAGS_TYPE_SUBCLASS        =(1 shl 31)

    Py_TPFLAGS_DEFAULT_EXTERNAL = Py_TPFLAGS_HAVE_GETCHARBUFFER or
                     Py_TPFLAGS_HAVE_SEQUENCE_IN or
                     Py_TPFLAGS_HAVE_INPLACEOPS or
                     Py_TPFLAGS_HAVE_RICHCOMPARE or
                     Py_TPFLAGS_HAVE_WEAKREFS or
                     Py_TPFLAGS_HAVE_ITER or
                     Py_TPFLAGS_HAVE_CLASS or
                     Py_TPFLAGS_HAVE_STACKLESS_EXTENSION or
                     Py_TPFLAGS_HAVE_INDEX

    Py_TPFLAGS_DEFAULT_CORE = Py_TPFLAGS_DEFAULT_EXTERNAL or Py_TPFLAGS_HAVE_VERSION_TAG

    # These flags are used for PyMethodDef.ml_flags
    Py_MLFLAGS_VARARGS  = (1 shl 0)
    Py_MLFLAGS_KEYWORDS = (1 shl 1)
    Py_MLFLAGS_NOARGS   = (1 shl 2)
    Py_MLFLAGS_O        = (1 shl 3)
    Py_MLFLAGS_CLASS    = (1 shl 4)
    Py_MLFLAGS_STATIC   = (1 shl 5)


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

    PyNamedArg = tuple
        name: cstring
        obj: PPyObject

    PyBaseType = enum
        pbUnknown
        pbLong
        pbFloat
        pbComplex
        pbCapsule # not used
        pbTuple
        pbList
        pbBytes
        pbUnicode
        pbDict
        pbString
        pbObject

proc privateRawPyObj*(p: PyObject): PPyObject {.inline.} =
    # Don't use this
    p.rawPyObj

proc addMethod(m: var PyModuleDesc, name, doc: cstring, f: PyCFunction) =
    let def = PyMethodDef(ml_name: name, ml_meth: f, ml_flags: Py_MLFLAGS_VARARGS,
                          ml_doc: doc)
    m.methods.add(def)

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

proc pyAlloc(sz: int): PPyObject {.inline.} =
    result = cast[PPyObject](alloc0(sz.uint + pyObjectStartOffset))

proc toNim(p: PPyObject, t: typedesc): t {.inline.} =
    result = cast[t](cast[uint](p) - uint(sizeof(PyObject_HEAD_EXTRA) + sizeof(pointer)))

proc initCommon(m: var PyModuleDesc) =
    if pyLib.isNil:
        pyLib = loadPyLibFromThisProcess()
    m.methods.add(PyMethodDef()) # Add sentinel

proc destructNimObj(o: PPyObject) {.cdecl.} =
    let n = toNim(o, PyNimObject)
    GC_unref(n)

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

proc toString*(b: RawPyBuffer): string =
    if not b.buf.isNil:
        let ln = b.len
        result = newString(ln)
        if ln != 0:
            copyMem(addr result[0], b.buf, ln)

proc pyObjToJson(o: PPyobject, n: var JsonNode)
proc pyObjToNimSeq[T](o: PPyObject, v: var seq[T])
proc pyObjToNimTab[T; U](o: PPyObject, tab: var Table[T, U])
proc pyObjToNimArray[T, I](o: PPyObject, s: var array[I, T])
proc pyObjToNimStr(o: PPyObject, v: var string) =
    if unlikely(not pyStringToNim(o, v)):
        # Name the type that is unable to be converted.
        let typ = cast[PyTypeObject]((cast[ptr PyObjectObj](o)).ob_type)
        let errString = "Can't convert python obj of type '$1' to string"
        raise newException(Exception, errString % [$typ.tp_name])

proc unknownTypeCompileError() {.inline.} =
    # This function never compiles, it is needed to see somewhat informative
    # compile time error
    discard

proc pyObjToNim[T](o: PPyObject, v: var T) {.inline.}

proc strToPyObject(s: string): PPyObject =
    var cs: cstring = s
    var ln = s.len.cint
    result = pyLib.Py_BuildValue("s#", cs, ln)
    if result.isNil:
        # Utf-8 decoding failed. Fallback to bytes.
        pyLib.PyErr_Clear()
        result = pyLib.Py_BuildValue("y#", cs, ln)

    assert(not result.isNil, "nimpy internal error converting string")

proc pyObjToNimObj(o: PPyObject, vv: var object) =
    for k, v in fieldPairs(vv):
        let f = pyLib.PyDict_GetItemString(o, k)
        pyObjToNim(f, v)
        # No DECREF here. PyDict_GetItemString returns a borrowed ref.

proc pyObjToNimTuple(o: PPyObject, vv: var tuple) =
    var i = 0
    for v in fields(vv):
        let f = pyLib.PyTuple_GetItem(o, i)
        pyObjToNim(f, v)
        # No DECREF here. PyTuple_GetItem returns a borrowed ref.
        inc i

proc finalizePyObject(o: PyObject) =
    decRef o.rawPyObj

proc newPyObjectConsumingRef(o: PPyObject): PyObject =
    assert(not o.isNil, "internal error")
    result.new(finalizePyObject)
    result.rawPyObj = o

proc newPyObject(o: PPyObject): PyObject =
    incRef o
    newPyObjectConsumingRef(o)

proc conversionError(toType: string) =
    pyLib.PyErr_Clear()
    raise newException(Exception, "Cannot convert python object to " & toType)

proc pyObjToNim[T](o: PPyObject, v: var T) {.inline.} =
    template conversionTypeCheck(what: untyped): untyped =
        if not checkObjSubclass(o, what):
            raise newException(Exception, "Cannot convert python object to " & $T)
    template conversionErrorCheck(): untyped =
        if unlikely(not pyLib.PyErr_Occurred().isNil):
            conversionError($T)

    when T is int|int32|int64|int16|uint32|uint64|uint16|uint8|int8|char:
        let ll = pyLib.PyLong_AsLongLong(o)
        if ll == -1: conversionErrorCheck()
        v = T(ll)
    elif T is float|float32|float64:
        v = T(pyLib.PyFloat_AsDouble(o))
        if v < 0: conversionErrorCheck()
    elif T is bool:
        v = bool(pyLib.PyObject_IsTrue(o))
    elif T is PPyObject:
        v = o
    elif T is PyObject:
        v = newPyObject(o)
    elif T is Complex:
        conversionTypeCheck(pyLib.PyComplex_Type)
        if unlikely pyLib.PyComplex_AsCComplex.isNil:
            v.re = pyLib.PyComplex_RealAsDouble(o)
            v.im = pyLib.PyComplex_ImagAsDouble(o)
        else:
            v = pyLib.PyComplex_AsCComplex(o)
    elif T is string:
        pyObjToNimStr(o, v)
    elif T is seq:
        conversionTypeCheck(pyLib.PyList_Type)
        pyObjToNimSeq(o, v)
    elif T is array:
        conversionTypeCheck(pyLib.PyList_Type)
        pyObjToNimArray(o, v)
    elif T is ref:
        if cast[pointer](o) == cast[pointer](pyLib.Py_None):
            v = nil
        else:
            conversionTypeCheck(pyLib.PyCapsule_Type)
            v = cast[T](pyLib.PyCapsule_GetPointer(o, nil))
    elif T is Table:
        # above `object` since `Table` is an object
        conversionTypeCheck(pyLib.PyDict_Type)
        pyObjToNimTab(o, v)
    elif T is object:
        pyObjToNimObj(o, v)
    elif T is tuple:
        conversionTypeCheck(pyLib.PyTuple_Type)
        pyObjToNimTuple(o, v)
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

proc pyObjToNimTab[T; U](o: PPyObject, tab: var Table[T, U]) =
    ## call this either:
    ## - if you want to check whether T and U are valid types for
    ##   the python dict (i.e. to check whether all python types
    ##   are convertible to T and U)
    ## - you know the python dict conforms to T and U and you wish
    ##   to get a correct Nim table from that
    tab = initTable[T, U]()
    let
        sz = int(pyLib.PyDict_Size(o))
        ks = pyLib.PyDict_Keys(o)
        vs = pyLib.PyDict_Values(o)
    for i in 0 ..< sz:
        var
            k: T
            v: U
        pyObjToNim(pyLib.PyList_GetItem(ks, i), k)
        pyObjToNim(pyLib.PyList_GetItem(vs, i), v)
        # PyList_GetItem # No DECREF. Returns borrowed ref.
        tab[k] = v
    decRef ks
    decRef vs

proc pyObjToNimArray[T, I](o: PPyObject, s: var array[I, T]) =
    # assert(PyList_Check(o) != 0)
    let sz = int(pyLib.PyList_Size(o))
    assert(sz == s.len)
    for i in 0 ..< sz:
        pyObjToNim(pyLib.PyList_GetItem(o, i), s[i])
        # PyList_GetItem # No DECREF. Returns borrowed ref.

proc nimArrToPy[T](s: openarray[T]): PPyObject
proc nimTabToPy[T: Table](t: T): PPyObject
proc nimObjToPy[T](o: T): PPyObject
proc nimTupleToPy[T](o: T): PPyObject
proc nimProcToPy[T](o: T): PPyObject

proc newPyNone*(): PPyObject {.inline.} =
    incRef(pyLib.Py_None)
    pyLib.Py_None

proc refCapsuleDestructor(c: PPyObject) {.cdecl.} =
    let o = pyLib.PyCapsule_GetPointer(c, nil)
    GC_unref(cast[ref int](o))

proc newPyCapsule[T](v: ref T): PPyObject =
    GC_ref(v)
    pyLib.PyCapsule_New(cast[pointer](v), nil, refCapsuleDestructor)

proc nimValueToPy[T](v: T): PPyObject {.inline.} =
    when T is void:
        newPyNone()
    elif T is PPyObject:
        v
    elif T is PyObject:
        if v.isNil:
            newPyNone()
        else:
            assert(not v.rawPyObj.isNil, "nimpy internal error rawPyObj.isNil")
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
    elif T is uint8|char:
        pyLib.Py_BuildValue("B", uint8(v))
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
            newPyNone()
        else:
            newPyCapsule(v)
    elif T is bool:
        pyLib.PyBool_FromLong(clong(v))
    elif T is Complex:
        pyLib.Py_BuildValue("D", unsafeAddr v)
    elif T is Table:
        nimTabToPy(v)
    elif T is object:
        nimObjToPy(v)
    elif T is tuple:
        nimTupleToPy(v)
    elif T is (proc):
        nimProcToPy(v)
    else:
        unknownTypeCompileError(v)

proc nimArrToPy[T](s: openarray[T]): PPyObject =
    let sz = s.len
    result = pyLib.PyList_New(sz)
    for i in 0 ..< sz:
        let o = nimValueToPy(s[i])
        discard pyLib.PyList_SetItem(result, i, o)

proc baseType(o: PPyObject): PyBaseType =
    # returns the correct PyBaseType of the given PyObject extracted
    # by manually checking all types
    # If no call to `returnIfSubclass` returns from this proc, the
    # default value of `pbUnknown` will be returned
    template returnIfSubclass(pyt, nimt: untyped): untyped =
        if checkObjSubclass(o, pyt):
            return nimt

    # check int types first for backward compatibility with Python2
    returnIfSubclass(Py_TPFLAGS_INT_SUBCLASS or Py_TPFLAGS_LONG_SUBCLASS, pbLong)

    let checkTypes = { pyLib.PyFloat_Type : pbFloat,
                       pyLib.PyComplex_Type : pbComplex,
                       pyLib.PyBytes_Type : pbString,
                       pyLib.PyUnicode_Type : pbString,
                       pyLib.PyList_Type : pbList,
                       pyLib.PyTuple_Type : pbTuple,
                       pyLib.PyDict_Type : pbDict }

    for tup in checkTypes:
        let
            k = tup[0]
            v = tup[1]
        returnIfSubclass(k, v)
    # if we have not returned until here, `pbUnknown` is returned

iterator items*(o: PyObject): PyObject =
    let it = pyLib.PyObject_GetIter(o.rawPyObj)
    while true:
        let i = pyLib.PyIter_Next(it)
        if i.isNil: break
        yield newPyObjectConsumingRef(i)
    decRef it

proc `$`*(p: PPyObject): string =
    assert(not p.isNil)
    let s = pyLib.PyObject_Str(p)
    pyObjToNimStr(s, result)
    decRef s

proc `$`*(o: PyObject): string {.inline.} = $o.rawPyObj

proc `%`(o: PPyObject): JsonNode =
    ## convert the given PPyObject to a JsonNode
    let bType = o.baseType
    case bType
    of pbUnknown:
        # unsupported means we just use string conversion
        result = % $o
    of pbLong:
        var x: int
        pyObjToNim(o, x)
        result = % x
    of pbFloat:
        var x: float
        pyObjToNim(o, x)
        result = % x
    of pbComplex:
        var x: Complex
        pyObjToNim(o, x)
        result = %* { "real" : x.re,
                      "imag" : x.im }
    of pbList, pbTuple:
        result = newJArray()
        let pyObj = PyObject(rawPyObj: o)
        for x in pyObj:
            add(result, % (x.rawPyObj))
    of pbBytes, pbUnicode, pbString:
        result = % $o
    of pbDict:
        # dictionaries are represented as `JObjects`, where the Python dict's keys
        # are stored as strings
        result = newJObject()
        let pyObj = PyObject(rawPyObj: o)
        for key in pyObj:
            let val = pyLib.PyDict_GetItem(o, key.rawPyObj)
            result[$key] = % val
    of pbObject: # not used, for objects currently end up as `pbUnknown`
        result = newJString($o)
    of pbCapsule: # not used
        raise newException(Exception, "Cannot store object of base type " &
            "`pbCapsule` in JSON.")

proc pyObjToJson(o: PPyObject, n: var JsonNode) =
    n = % o

proc PyObject_CallObject(o: PPyObject): PPyObject =
    let args = pyLib.PyTuple_New(0)
    result = pyLib.PyObject_Call(o, args, nil)
    decRef args

proc cannotSerializeErr(k: string) =
    raise newException(Exception, "Could not serialize object key: " & k)

proc nimTabToPy[T: Table](t: T): PPyObject =
    result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
    for k, v in pairs(t):
        let vv = nimValueToPy(v)
        when type(k) is string:
            let ret = pyLib.PyDict_SetItemString(result, k, vv)
        else:
            let kk = nimValueToPy(k)
            let ret = pyLib.PyDict_SetItem(result, kk, vv)
            decRef kk
        decRef vv
        if ret != 0:
            cannotSerializeErr($k)

proc nimObjToPy[T](o: T): PPyObject =
    result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
    for k, v in fieldPairs(o):
        let vv = nimValueToPy(v)
        let ret = pyLib.PyDict_SetItemString(result, k, vv)
        decRef vv
        if ret != 0:
            cannotSerializeErr(k)

proc tupleSize[T](): int {.compileTime.} =
    var o: T
    for f in fields(o): inc result

proc nimTupleToPy[T](o: T): PPyObject =
    const sz = tupleSize[T]()
    result = pyLib.PyTuple_new(sz)
    var i = 0
    for f in fields(o):
        discard pyLib.PyTuple_SetItem(result, i, nimValueToPy(f))
        inc i

proc parseArg[T](argTuple: PPyObject, argIdx: int, result: var T) =
    pyObjToNim(pyLib.PyTuple_GetItem(argTuple, argIdx), result)

proc parseArg[T](argTuple: PPyObject, argIdx: int, default: T, result: var T) =
    if argIdx < pyLib.PyTuple_Size(argTuple):
        pyObjToNim(pyLib.PyTuple_GetItem(argTuple, argIdx), result)
    else:
        result = default

proc verifyArgs(argTuple: PPyObject, argsLen, argsLenReq: int, funcName: string): bool =
    let sz = pyLib.PyTuple_Size(argTuple)
    result = if argsLen > argsLenReq:
        # We have some optional arguments, argsLen is the upper limit
        sz >= argsLenReq and sz <= argsLen
    else:
        sz == argsLen
    if not result:
        pyLib.PyErr_SetString(pyLib.PyExc_TypeError, funcName & "() takes exactly " & $argsLen & " arguments (" & $sz & " given)")

template seqTypeForOpenarrayType[T](t: type openarray[T]): typedesc = seq[T]
template valueTypeForArgType(t: typedesc): typedesc =
    when t is openarray:
        seqTypeForOpenarrayType(t)
    else:
        t

proc updateStackBottom() {.inline.} =
    when declared(nimGC_setStackBottom):
        var a: int
        nimGC_setStackBottom(addr a)
    elif not defined(nimpySuppressGCCrashWarning):
        {.error: "Use newer Nim, or compile with -d:nimpySuppressGCCrashWarning and experience potential crashes in GC".}

iterator arguments(prc: NimNode): tuple[idx: int, name, typ, default: NimNode] =
    var formalParams: NimNode
    if prc.kind == nnkProcDef:
        formalParams = prc.params
    elif prc.kind == nnkProcTy:
        formalParams = prc[0]
    else:
        # Assume prc is typed
        var impl = getImpl(prc)
        if impl.kind == nnkNilLit:
            impl = getTypeImpl(prc)
            expectKind(impl, nnkProcTy)
            formalParams = impl[0]
        else:
            if impl.kind != nnkProcDef:
              echo treeRepr(impl)
            expectKind(impl, nnkProcDef)
            formalParams = impl.params

    var iParam = 0
    for i in 1 ..< formalParams.len:
        let pp = formalParams[i]
        for j in 0 .. pp.len - 3:
            yield (iParam, pp[j], copyNimTree(pp[^2]), pp[^1])
            inc iParam

macro callNimProcWithPythonArgs(prc: typed, argsTuple: PPyObject): PPyObject =
    let pyValueVarSection = newNimNode(nnkVarSection)

    let parseArgsStmts = newNimNode(nnkStmtList)
    parseArgsStmts.add(pyValueVarSection)
    let origCall = newCall(prc)

    var numArgs = 0
    var numArgsReq = 0
    for a in prc.arguments:
        let argIdent = newIdentNode("arg" & $a.idx & $a.name)
        # XXX: The newCall("type", a.typ) should be just `a.typ` but compilation fails. Nim bug?
        pyValueVarSection.add(newIdentDefs(argIdent, newCall(bindSym"valueTypeForArgType", newCall("type", a.typ))))
        if a.default.kind != nnkEmpty:
            parseArgsStmts.add(newCall(bindSym"parseArg", argsTuple, newLit(a.idx), a.default, argIdent))
        elif numArgsReq < numArgs:
            # Exported procedures _must_ have all their arguments w/ a default
            # value follow the required ones
            error("Default-valued arguments must follow the regular ones", prc)
        else:
            parseArgsStmts.add(newCall(bindSym"parseArg", argsTuple, newLit(a.idx), argIdent))
            inc numArgsReq
        origCall.add(argIdent)
        inc numArgs

    let argsLen = newLit(numArgs)
    let argsLenReq = newLit(numArgsReq)
    let nameLit = newLit($prc)
    result = quote do:
        updateStackBottom()
        if verifyArgs(`argsTuple`, `argsLen`, `argsLenReq`, `nameLit`):
            `parseArgsStmts`
            nimValueToPy(`origCall`)
        else:
            PPyObject(nil)

type NimPyProcBase* = ref object {.inheritable, pure.}
    c: proc(args: PPyObject, p: NimPyProcBase): PPyObject {.cdecl.}

proc callNimProc(self, args: PPyObject): PPyObject {.cdecl.} =
    let np = cast[NimPyProcBase](pyLib.PyCapsule_GetPointer(self, nil))
    np.c(args, np)

proc nimProcToPy[T](o: T): PPyObject =
    var md {.global.}: PyMethodDef
    if md.ml_name.isNil:
        md.ml_name = "anonymous"
        md.ml_flags = Py_MLFLAGS_VARARGS
        md.ml_meth = callNimProc

    type NimProcS[T] = ref object of NimPyProcBase
        p: T

    proc doCall(args: PPyObject, p: NimPyProcBase): PPyObject {.cdecl.} =
        var anonymous: T
        anonymous = cast[NimProcS[T]](p).p
        callNimProcWithPythonArgs(anonymous, args)

    let np = NimProcS[T](p: o, c: doCall)
    let self = newPyCapsule(np)
    result = pyLib.PyCFunction_NewEx(addr md, self, nil)
    decRef self

proc makeWrapper(originalName: string, name, prc: NimNode): NimNode =
    let selfIdent = newIdentNode("self")
    let argsIdent = newIdentNode("args")
    result = newProc(name, params = [bindSym"PPyObject", newIdentDefs(selfIdent, bindSym"PPyObject"), newIdentDefs(argsIdent, bindSym"PPyObject")])
    result.addPragma(newIdentNode("cdecl"))
    result.body = newCall(bindSym("callNimProcWithPythonArgs"), prc.name, argsIdent)

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
    if procName.len == 0:
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

proc toJson*(v: PyObject): JsonNode {.inline.} =
    pyObjToJson(v.rawPyObj, result)

proc callMethodAux(o: PyObject, name: cstring, args: openarray[PPyObject], kwargs: openarray[PyNamedArg] = []): PPyObject =
    let callable = pyLib.PyObject_GetAttrString(o.rawPyObj, name)
    if callable.isNil:
        raise newException(Exception, "No callable attribute: " & $name)

    let argTuple = pyLib.PyTuple_New(args.len)
    for i, v in args:
        assert(not v.isNil, "nimpy internal error v.isNil")
        discard pyLib.PyTuple_SetItem(argTuple, i, v)

    var argDict: PPyObject = nil
    if kwargs.len > 0:
        argDict = pyLib.PyDict_New()
        for v in kwargs:
            assert(not v.obj.isNil, "nimpy internal error v.obj.isNil")
            discard pyLib.PyDict_SetItemString(argDict, v.name, v.obj)

    result = pyLib.PyObject_Call(callable, argTuple, argDict)
    decRef argTuple
    decRef callable

    if unlikely result.isNil:
        raisePythonError()

proc callMethod*(o: PyObject, name: cstring, args: varargs[PPyObject, toPyObjectArgument]): PyObject {.inline.} =
    newPyObjectConsumingRef(callMethodAux(o, name, args))

proc callMethod*(o: PyObject, ResultType: typedesc, name: cstring, args: varargs[PPyObject, toPyObjectArgument]): ResultType {.inline.} =
    let res = callMethodAux(o, name, args)
    pyObjToNim(res, result)
    decRef res

proc getProperty*(o: PyObject, name: cstring): PyObject =
    let r = pyLib.PyObject_GetAttrString(o.rawPyObj, name)
    if not r.isNil:
        result = newPyObjectConsumingRef(r)

macro dotCall(o: untyped, field: untyped, args: varargs[untyped]): untyped =
    expectKind(field, nnkIdent)

    let plainArgs = newTree(nnkBracket)
    let kwArgs = newTree(nnkBracket)

    for arg in args:
        # Skip the bogus [] `args` when no argument is passed
        if arg.kind == nnkHiddenStdConv and arg[0].kind == nnkEmpty:
            continue
        elif arg.kind != nnkExprEqExpr:
            plainArgs.add(newCall("toPyObjectArgument", arg))
        else:
            expectKind(arg[0], nnkIdent)
            kwArgs.add(newTree(nnkPar,
                newCall("cstring", newLit($arg[0])),
                newCall("toPyObjectArgument", arg[1])))

    result = newCall(bindSym"newPyObjectConsumingRef",
        newCall(bindSym"callMethodAux", o, newLit($field), plainArgs, kwArgs))

template `.()`*(o: PyObject, field: untyped, args: varargs[untyped]): PyObject =
    dotCall(o, field, args)

template `.`*(o: PyObject, field: untyped): PyObject =
    getProperty(o, astToStr(field))

proc elemAtIndex(o: PyObject, idx: PPyObject): PyObject =
    let r = pyLib.PyObject_GetItem(o.rawPyObj, idx)
    decRef idx
    if r.isNil: raisePythonError()
    newPyObjectConsumingRef(r)

proc setElemAtIndex(o: PyObject, idx, val: PPyObject) =
    let r = pyLib.PyObject_SetItem(o.rawPyObj, idx, val)
    decRef idx
    decRef val
    if r < 0: raisePythonError()

proc `[]`*[K](o: PyObject, idx: K): PyObject =
    o.elemAtIndex(toPyObjectArgument(idx))

proc `[]=`*[K, V](o: PyObject, idx: K, val: V) =
    o.setElemAtIndex(toPyObjectArgument(idx), toPyObjectArgument(val))

proc pyImport*(moduleName: cstring): PyObject =
    initPyLibIfNeeded()
    let o = pyLib.PyImport_ImportModule(moduleName)
    if unlikely o.isNil: raisePythonError()
    result = newPyObjectConsumingRef(o)

proc pyBuiltins*(): PyObject =
    initPyLibIfNeeded()
    newPyObject(pyLib.PyEval_GetBuiltins())

proc pyGlobals*(): PyObject =
    initPyLibIfNeeded()
    newPyObject(pyLib.PyEval_GetGlobals())

proc pyLocals*(): PyObject =
    initPyLibIfNeeded()
    newPyObject(pyLib.PyEval_GetLocals())

proc dir*(v: PyObject): seq[string] =
    let lst = pyLib.PyObject_Dir(v.rawPyObj)
    pyObjToNim(lst, result)
    decRef lst

proc pyBuiltinsModule*(): PyObject =
    initPyLibIfNeeded()
    pyImport(if pyLib.pythonVersion == 3: "builtins" else: "__builtin__")
