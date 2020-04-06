import dynlib, macros, os, strutils, complex, typetraits, tables, json,
  nimpy/[py_types, py_utils]

import nimpy/py_lib as lib

type
  PyObject* = ref object
    rawPyObj: PPyObject

  PyNimObject {.inheritable.} = ref object
    py_extra_dont_use: PyObject_HEAD_EXTRA
    py_object: PyObjectObj

  PyNimObjectBaseToInheritFromForAnExportedType* = PyNimObject

const
  #  PyBufferProcs contains bf_getcharbuffer
  Py_TPFLAGS_HAVE_GETCHARBUFFER  = (1 shl 0)

  #  PySequenceMethods contains sq_contains
  Py_TPFLAGS_HAVE_SEQUENCE_IN = (1 shl 1)

# This is here for backwards compatibility.  Extensions that use the old GC
# API will still compile but the objects will not be tracked by the GC.
#  Py_TPFLAGS_GC 0 #  used to be (1 shl 2) =

  #  PySequenceMethods and PyNumberMethods contain in-place operators
  Py_TPFLAGS_HAVE_INPLACEOPS = (1 shl 3)

  #  PyNumberMethods do their own coercion
  Py_TPFLAGS_CHECKTYPES = (1 shl 4)

  #  tp_richcompare is defined
  Py_TPFLAGS_HAVE_RICHCOMPARE = (1 shl 5)

  #  Objects which are weakly referencable if their tp_weaklistoffset is >0
  Py_TPFLAGS_HAVE_WEAKREFS = (1 shl 6)

  #  tp_iter is defined
  Py_TPFLAGS_HAVE_ITER = (1 shl 7)

  #  New members introduced by Python 2.2 exist
  Py_TPFLAGS_HAVE_CLASS = (1 shl 8)

  #  Set if the type object is dynamically allocated
  Py_TPFLAGS_HEAPTYPE = (1 shl 9)

  #  Set if the type allows subclassing
  Py_TPFLAGS_BASETYPE = (1 shl 10)

  #  Set if the type is 'ready' -- fully initialized
  Py_TPFLAGS_READY = (1 shl 12)

  #  Set while the type is being 'readied', to prevent recursive ready calls
  Py_TPFLAGS_READYING = (1 shl 13)

  #  Objects support garbage collection (see objimp.h)
  Py_TPFLAGS_HAVE_GC = (1 shl 14)

  #  These two bits are preserved for Stackless Python, next after this is 17

  Py_TPFLAGS_HAVE_STACKLESS_EXTENSION =0

  #  Objects support nb_index in PyNumberMethods
  Py_TPFLAGS_HAVE_INDEX = (1 shl 17)

  #  Objects support type attribute cache
  Py_TPFLAGS_HAVE_VERSION_TAG   = (1 shl 18)
  Py_TPFLAGS_VALID_VERSION_TAG  = (1 shl 19)

  #  Type is abstract and cannot be instantiated
  Py_TPFLAGS_IS_ABSTRACT = (1 shl 20)

  #  Has the new buffer protocol
  Py_TPFLAGS_HAVE_NEWBUFFER = (1 shl 21)

  #  These flags are used to determine if a type is a subclass.
  Py_TPFLAGS_INT_SUBCLASS       = (1 shl 23)
  Py_TPFLAGS_LONG_SUBCLASS      = (1 shl 24)
  Py_TPFLAGS_LIST_SUBCLASS      = (1 shl 25)
  Py_TPFLAGS_TUPLE_SUBCLASS     = (1 shl 26)
  Py_TPFLAGS_STRING_SUBCLASS    = (1 shl 27)
  Py_TPFLAGS_UNICODE_SUBCLASS   = (1 shl 28)
  Py_TPFLAGS_DICT_SUBCLASS      = (1 shl 29)
  Py_TPFLAGS_BASE_EXC_SUBCLASS  = (1 shl 30)
  Py_TPFLAGS_TYPE_SUBCLASS      = (1 shl 31)

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
  Py_MLFLAGS_O    = (1 shl 3)
  Py_MLFLAGS_CLASS  = (1 shl 4)
  Py_MLFLAGS_STATIC   = (1 shl 5)

  # Rich comparison opcodes
  Py_LT = 0
  Py_LE = 1
  Py_EQ = 2
  Py_NE = 3
  Py_GT = 4
  Py_GE = 5

type
  PyModuleDesc = object
    name: cstring
    doc: cstring
    methods: seq[PyMethodDef]
    types: seq[PyTypeDesc]
    iterators: seq[PyIteratorDesc]

  PyIteratorDesc = object
    name: cstring
    doc: cstring
    newFunc: Newfunc

  PyTypeDesc = object
    module: ptr PyModuleDesc
    name: cstring
    doc: cstring
    fullName: string
    newFunc: Newfunc
    methods: seq[PyMethodDef]
    members: seq[PyMemberDef]
    origSize: int

  PyIterRef = ref object
    iter: iterator(): PPyObject

  PyIteratorObj = object of PyObjectVarHeadObj
    iRef: PyIterRef

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

proc addMethod(m: var PyModuleDesc, name, doc: cstring, f: PyCFunctionWithKeywords) =
  let def = PyMethodDef(ml_name: name, ml_meth: f, ml_flags: Py_MLFLAGS_VARARGS or Py_MLFLAGS_KEYWORDS,
              ml_doc: doc)
  m.methods.add(def)

proc addIterator(m: var PyModuleDesc, name, doc: cstring, newFunc: Newfunc) =
  m.iterators.add(PyIteratorDesc(name: name, doc: doc, newFunc: newFunc))

proc newNimObjToPyObj(typ: PyTypeObject, o: PyNimObject): PPyObject =
  GC_ref(o)
  result = cast[PPyObject](addr o.py_object)
  o.py_object.ob_type = typ
  o.py_object.ob_refcnt = 1

proc newPyNimObject[T](typ: PyTypeObject, args, kwds: PPyObject): PPyObject {.cdecl.} =
  newNimObjToPyObj(typ, T.new())

proc initPythonModuleDesc(m: var PyModuleDesc, name, doc: cstring) =
  m.name = name
  m.doc = doc

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

proc destructNimIterator(o: PPyObject) {.cdecl.} =
  let n = to(o, PyIteratorObj)
  GC_unref(n.iRef)

when compileOption("threads"):
  var gcInited {.threadVar.}: bool

proc updateStackBottom() {.inline.} =
  when not defined(gcDestructors):
    var a {.volatile.}: int
    nimGC_setStackBottom(cast[pointer](cast[uint](addr a)))
    when compileOption("threads") and not compileOption("tlsEmulation"):
      if not gcInited:
        gcInited = true
        setupForeignThreadGC()

proc pythonException(e: ref Exception): PPyObject =
  let err = pyLib.PyErr_NewException("nimpy" & "." & $(e.name), pyLib.NimPyException, nil)
  decRef err
  pyLib.PyErr_SetString(err, "Unexpected error encountered: " & getCurrentExceptionMsg())

proc iterNext(i: PPyObject): PPyObject {.cdecl.} =
  updateStackBottom()
  try:
    i.to(PyIteratorObj).iRef.iter()
  except Exception as e:
    pythonException(e)

proc initModuleTypes[PyTypeObj](p: PPyObject, m: PyModuleDesc) =
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

  let selfIter = if m.iterators.len != 0:
      cast[Getiterfunc](pyLib.module.symAddr("PyObject_SelfIter"))
    else:
      nil

  for i in 0 ..< m.iterators.len:
    let typ = pyAlloc(sizeof(PyTypeObj))
    let ty = typ.to(PyTypeObj)
    ty.tp_name = m.iterators[i].name

    ty.tp_basicsize = sizeof(PyIteratorObj)
    ty.tp_flags = Py_TPFLAGS_DEFAULT_EXTERNAL
    ty.tp_doc = m.iterators[i].doc
    ty.tp_new = m.iterators[i].newFunc
    ty.tp_free = freeNimObj
    ty.tp_dealloc = destructNimIterator
    ty.tp_iternext = cast[Iternextfunc](iterNext)
    ty.tp_iter = selfIter

    discard pyLib.PyType_Ready(cast[PyTypeObject](typ))
    incRef(typ)
    discard pyLib.PyModule_AddObject(p, m.iterators[i].name, typ)


  pyLib.NimPyException = pyLib.PyErr_NewException("nimpy.NimPyException", nil, nil)
  discard pyLib.PyModule_AddObject(p, "NimPyException", pyLib.NimPyException)

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

template declarePyModuleIfNeededAux(name, doc: static[cstring]) =
  when not declared(gPythonLocalModuleDesc):
    exportedModuleNames.add(name) # in py_lib.nim
    var gPythonLocalModuleDesc {.inject.}: PyModuleDesc
    initPythonModuleDesc(gPythonLocalModuleDesc, name, doc)
    {.push stackTrace: off.}
    proc py2init() {.exportc: "init" & name, dynlib.} =
      initModule2(gPythonLocalModuleDesc)

    proc py3init(): PPyObject {.exportc: "PyInit_" & name, dynlib.} =
      initModule3(gPythonLocalModuleDesc)
    {.pop.}

template declarePyModuleIfNeeded() =
  const moduleName = splitFile(instantiationInfo(0).filename).name
  declarePyModuleIfNeededAux(moduleName, "")

template pyExportModuleName*(n: static[cstring]) {.deprecated: "Use pyExportModule instead".} =
  when declared(gPythonLocalModuleDesc):
    {.error: "pyExportModuleName can be used only once per module and should come before all exportpy definitions".}
  else:
    declarePyModuleIfNeededAux(n, "")

template pyExportModule*(name: static[cstring] = "", doc: static[cstring] = "") =
  when declared(gPythonLocalModuleDesc):
    {.error: "pyExportModule can be used only once per module and should come before all exportpy definitions".}
  else:
    declarePyModuleIfNeededAux(name, doc)

################################################################################
################################################################################
################################################################################

proc toString*(b: RawPyBuffer): string =
  if not b.buf.isNil:
    let ln = b.len
    result = newString(ln)
    if ln != 0:
      copyMem(addr result[0], b.buf, ln)

proc pyObjToJson(o: PPyobject): JsonNode
proc pyObjToNimSeq[T](o: PPyObject, v: var seq[T])
proc pyObjToNimTab[T; U](o: PPyObject, tab: var Table[T, U])
proc pyObjToNimArray[T, I](o: PPyObject, v: var array[I, T])
proc pyObjToProc[T](o: PPyObject, v: var T)
proc pyObjToNimTuple(o: PPyObject, v: var tuple)

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
    if not f.isNil:
      pyObjToNim(f, v)
    # No DECREF here. PyDict_GetItemString returns a borrowed ref.

proc finalizePyObject(o: PyObject) =
  decRef o.rawPyObj

proc newPyObjectConsumingRef(o: PPyObject): PyObject =
  assert(not o.isNil, "internal error")
  result.new(finalizePyObject)
  result.rawPyObj = o

proc newPyObject(o: PPyObject): PyObject =
  incRef o
  newPyObjectConsumingRef(o)

proc raiseConversionError(toType: string) =
  raise newException(Exception, "Cannot convert python object to " & toType)

proc clearAndRaiseConversionError(toType: string) =
  pyLib.PyErr_Clear()
  raiseConversionError(toType)

proc pyObjToNim[T](o: PPyObject, v: var T) {.inline.} =
  template conversionTypeCheck(what: untyped): untyped {.used.} =
    if not checkObjSubclass(o, what):
      raiseConversionError($T)
  template conversionErrorCheck(): untyped {.used.} =
    if unlikely(not pyLib.PyErr_Occurred().isNil):
      clearAndRaiseConversionError($T)

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
      let vv = pyLib.PyComplex_AsCComplex(o)
      when declared(Complex64):
        when T is Complex64:
          v = vv
        else:
          v.re = vv.re
          v.im = vv.im
      else:
        v = vv
  elif T is string:
    pyObjToNimStr(o, v)
  elif T is seq:
    pyObjToNimSeq(o, v)
  elif T is array:
    pyObjToNimArray(o, v)
  elif T is JsonNode:
    v = pyObjToJson(o)
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
    pyObjToNimTuple(o, v)
  elif T is proc {.closure.}:
    pyObjToProc(o, v)
  else:
    unknownTypeCompileError(v)

proc getListOrTupleAccessors(o: PPyObject):
    tuple[getSize: proc(l: PPyObject): Py_ssize_t {.cdecl.},
      getItem: proc(l: PPyObject, index: Py_ssize_t): PPyObject {.cdecl.}] =
  if checkObjSubclass(o, pyLib.PyList_Type):
    result.getSize = pyLib.PyList_Size
    result.getItem = pyLib.PyList_GetItem
  elif checkObjSubclass(o, pyLib.PyTuple_Type):
    result.getSize = pyLib.PyTuple_Size
    result.getItem = pyLib.PyTuple_GetItem

proc pyObjFillArray[T](o: PPyObject, getItem: proc(l: PPyObject, index: Py_ssize_t): PPyObject {.cdecl.}, v: var openarray[T]) =
  for i in 0 ..< v.len:
    pyObjToNim(getItem(o, i), v[i])
    # No DECREF. getItem returns borrowed ref.

proc pyObjToNimSeq[T](o: PPyObject, v: var seq[T]) =
  let (getSize, getItem) = getListOrTupleAccessors(o)
  if unlikely getSize.isNil:
    raiseConversionError($type(v))

  let sz = int(getSize(o))
  assert(sz >= 0)
  v = newSeq[T](sz)
  pyObjFillArray(o, getItem, v)

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

proc pyObjToNimArray[T, I](o: PPyObject, v: var array[I, T]) =
  let (getSize, getItem) = getListOrTupleAccessors(o)
  if not getSize.isNil:
    let sz = int(getSize(o))
    if sz == v.len:
      pyObjFillArray(o, getItem, v)
      return

  raiseConversionError($type(v))

proc tupleSize[T](): int {.compileTime.} =
  var o: T
  for f in fields(o): inc result

proc pyObjToNimTuple(o: PPyObject, v: var tuple) =
  let (getSize, getItem) = getListOrTupleAccessors(o)
  const sz = tupleSize[type(v)]()
  if not getSize.isNil and getSize(o) == sz:
    var i = 0
    for f in fields(v):
      let pf = getItem(o, i)
      pyObjToNim(pf, f)
      # No DECREF here. PyTuple_GetItem returns a borrowed ref.
      inc i
  else:
    raiseConversionError($type(v))


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
  elif T is cstring:
    pyLib.Py_BuildValue("s", v)
  elif T is int32:
    pyLib.Py_BuildValue("i", v)
  elif T is int64:
    pyLib.Py_BuildValue("L", v)
  elif T is int:
    when sizeof(int) == sizeof(int64):
      nimValueToPy(int64(v))
    elif sizeof(int) == sizeof(int32):
      nimValueToPy(int32(v))
    elif sizeof(int) == sizeof(int16):
      nimValueToPy(int16(v))
    elif sizeof(int) == sizeof(int8):
      nimValueToPy(int8(v))
    else:
      {.error: "Unkown int size".}
  elif T is uint:
    when sizeof(uint) == sizeof(uint64):
      nimValueToPy(uint64(v))
    elif sizeof(uint) == sizeof(uint32):
      nimValueToPy(uint32(v))
    elif sizeof(uint) == sizeof(uint16):
      nimValueToPy(uint16(v))
    elif sizeof(uint) == sizeof(uint8):
      nimValueToPy(uint8(v))
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
    when declared(Complex64):
      when T is Complex64:
        pyLib.Py_BuildValue("D", unsafeAddr v)
      else:
        let vv = complex64(v.re, v.im)
        pyLib.Py_BuildValue("D", unsafeAddr vv)
    else:
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

iterator rawItems(o: PPyObject): PPyObject =
  let it = pyLib.PyObject_GetIter(o)
  defer: decRef it
  while true:
    let i = pyLib.PyIter_Next(it)
    if i.isNil: break
    yield i

iterator items*(o: PyObject): PyObject =
  for i in o.rawPyObj.rawItems:
    yield newPyObjectConsumingRef(i)

proc pyDictHasKey(o: PPyObject, k: cstring): bool =
  # TODO: should we check if o is a dict?
  let pk = pyLib.PyUnicode_FromString(k)
  result = pyLib.PyDict_Contains(o, pk) == 1
  decRef pk

proc `==`(o: PPyObject, k: cstring): bool =
  if pyLib.PyUnicode_CompareWithASCIIString.isNil:
    result = pyLib.PyString_AsString(o) == k
  else:
    result = pyLib.PyUnicode_CompareWithASCIIString(o, k) == 0

proc `$`(p: PPyObject): string =
  assert(not p.isNil)
  let s = pyLib.PyObject_Str(p)
  pyObjToNimStr(s, result)
  decRef s

proc `$`*(o: PyObject): string {.inline.} = $o.rawPyObj

proc pyObjToJson(o: PPyObject): JsonNode =
  ## convert the given PPyObject to a JsonNode
  let bType = o.baseType
  case bType
  of pbUnknown:
    # unsupported means we just use string conversion
    result = % $o
  of pbLong:
    var x: int
    pyObjToNim(o, x)
    result = %x
  of pbFloat:
    var x: float
    pyObjToNim(o, x)
    result = %x
  of pbComplex:
    when declared(Complex64):
      var x: Complex64
    else:
      var x: Complex

    pyObjToNim(o, x)
    result = %*{ "real" : x.re,
           "imag" : x.im }
  of pbList, pbTuple:
    result = newJArray()
    for x in o.rawItems:
      result.add(pyObjToJson(x))
      decRef x

  of pbBytes, pbUnicode, pbString:
    result = % $o
  of pbDict:
    # dictionaries are represented as `JObjects`, where the Python dict's keys
    # are stored as strings
    result = newJObject()
    for key in o.rawItems:
      let val = pyLib.PyDict_GetItem(o, key)
      result[$key] = pyObjToJson(val)
      decRef key
      # No DECREF for val here. PyDict_GetItem returns a borrowed ref.

  of pbObject: # not used, for objects currently end up as `pbUnknown`
    result = % $o
  of pbCapsule: # not used
    raise newException(Exception, "Cannot store object of base type " &
      "`pbCapsule` in JSON.")

proc PyObject_CallObject(o: PPyObject): PPyObject =
  let args = pyLib.PyTuple_New(0)
  result = pyLib.PyObject_Call(o, args, nil)
  decRef args

proc cannotSerializeErr(k: string) =
  raise newException(Exception, "Could not serialize object key: " & k)

proc nimTabToPy[T: Table](t: T): PPyObject =
  result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
  for k, v in t:
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

proc nimTupleToPy[T](o: T): PPyObject =
  const sz = tupleSize[T]()
  result = pyLib.PyTuple_new(sz)
  var i = 0
  for f in fields(o):
    discard pyLib.PyTuple_SetItem(result, i, nimValueToPy(f))
    inc i

proc getPyArg(argTuple, argDict: PPyObject, argIdx: int, argName: cstring): PPyObject =
  # argTuple can never be nil
  if argIdx < pyLib.PyTuple_Size(argTuple):
    result = pyLib.PyTuple_GetItem(argTuple, argIdx)
  if result.isNil and not argDict.isNil:
    result = pyLib.PyDict_GetItemString(argDict, argName)

proc parseArg[T](argTuple, kwargsDict: PPyObject, argIdx: int, argName: cstring, result: var T) =
  let arg = getPyArg(argTuple, kwargsDict, argIdx, argName)
  if not arg.isNil:
    pyObjToNim(arg, result)
  # TODO: What do we do if arg is nil???

template raisePyException(tp, msg: untyped): untyped =
  when not defined(gcDestructors):
    GC_disable()
  pyLib.PyErr_SetString(tp, msg)
  when not defined(gcDestructors):
    GC_enable()
  return false

proc verifyArgs(argTuple, kwargsDict: PPyObject, argsLen, argsLenReq: int, argNames: openarray[cstring], funcName: string): bool =
  # WARNING! Do not let GC happen in this proc!
  let
    nargs = if argTuple.isNil: 0 else: pyLib.PyTuple_Size(argTuple)
    nkwargs = if kwargsDict.isNil: 0 else: pyLib.PyDict_Size(kwargsDict)
    sz = nargs + nkwargs
  var
    nkwarg_left = nkwargs

  result = if argsLen > argsLenReq:
    # We have some optional arguments, argsLen is the upper limit
    sz >= argsLenReq and sz <= argsLen
  else:
    sz == argsLen

  if not result:
    raisePyException(pyLib.PyExc_TypeError, funcName & "() takes exactly " & $argsLen & " arguments (" & $sz & " given)")

  for i in 0..<sz:
    # maybe is arg
    if i < nargs:
      continue
    # we get required kwarg
    elif i < argsLenReq and nkwargs > 0:
      if not pyDictHasKey(kwargsDict, argNames[i]):
        raisePyException(pyLib.PyExc_TypeError, funcName & "() missing 1 required positional argument: " & $argNames[i])
      else:
        dec nkwarg_left
    # we get optional kwarg
    elif nkwargs > 0:
      if pyDictHasKey(kwargsDict, argNames[i]):
        dec nkwarg_left

  # something is wrong, find out what
  if nkwarg_left > 0:
    # maybe we have args also defined as kwargs
    if nargs > 0:
      for i in 0..nargs:
        if pyDictHasKey(kwargsDict, argNames[i]):
          raisePyException(pyLib.PyExc_TypeError, funcName & "() got multiple values for argument " & $argNames[i])

    # maybe we have an invalid kwarg
    for k in kwargsDict.rawItems:
      var found = false
      for a in argNames:
        if k == a:
          found = true
          break
      if likely found:
        decRef k
      else:
        let kStr = $k
        decRef k
        raisePyException(pyLib.PyExc_TypeError, funcName & "() got an unexpected keyword argument " & kStr)

template seqTypeForOpenarrayType[T](t: type openarray[T]): typedesc = seq[T]
template valueTypeForArgType(t: typedesc): typedesc =
  when t is openarray:
    seqTypeForOpenarrayType(t)
  else:
    t

proc getFormalParams(prc: NimNode): NimNode =
  if prc.kind in {nnkProcDef, nnkFuncDef, nnkIteratorDef}:
    result = prc.params
  elif prc.kind == nnkProcTy:
    result = prc[0]
  else:
    # Assume prc is typed
    var impl = getImpl(prc)
    if impl.kind in {nnkProcDef, nnkFuncDef}:
      result = impl.params
    else:
      let ty = getTypeImpl(prc)
      expectKind(ty, nnkProcTy)
      result = ty[0]
  result.expectKind(nnkFormalParams)

iterator arguments(formalParams: NimNode): tuple[idx: int, name, typ, default: NimNode] =
  formalParams.expectKind(nnkFormalParams)
  var iParam = 0
  for i in 1 ..< formalParams.len:
    let pp = formalParams[i]
    for j in 0 .. pp.len - 3:
      yield (iParam, pp[j], copyNimTree(pp[^2]), pp[^1])
      inc iParam

proc makeCallNimProcWithPythonArgs(prc, formalParams, argsTuple, kwargsDict: NimNode): tuple[parseArgs, call: NimNode] =
  let
    pyValueVarSection = newNimNode(nnkVarSection)
    parseArgsStmts = newNimNode(nnkStmtList)

  parseArgsStmts.add(pyValueVarSection)

  let
    origCall = newCall(prc)

  var
    numArgs = 0
    numArgsReq = 0
    argNames = newNimNode(nnkBracket)

  for a in formalParams.arguments:
    let argIdent = newIdentNode("arg" & $a.idx & $a.name)
    let argName = $a.name
    argNames.add(newCall(ident"cstring", newLit(argName)))
    if a.typ.kind == nnkEmpty:
      error("Typeless arguments are not supported by nimpy: " & $a.name, a.name)
    # XXX: The newCall("type", a.typ) should be just `a.typ` but compilation fails. Nim bug?
    if a.default.kind != nnkEmpty:
      # if we have a default, set it during var declaration
      pyValueVarSection.add(newIdentDefs(argIdent, newCall(bindSym"valueTypeForArgType", newCall("type", a.typ)), a.default))
    elif numArgsReq < numArgs:
      # Exported procedures _must_ have all their arguments w/ a default
      # value follow the required ones
      error("Default-valued arguments must follow the regular ones", prc)
    else:
      pyValueVarSection.add(newIdentDefs(argIdent, newCall(bindSym"valueTypeForArgType", newCall("type", a.typ))))
      inc numArgsReq
    parseArgsStmts.add(newCall(bindSym"parseArg", argsTuple, kwargsDict,
                   newLit(a.idx), newLit(argName), argIdent))
    origCall.add(argIdent)
    inc numArgs

  let
    argsLen = newLit(numArgs)
    argsLenReq = newLit(numArgsReq)
    nameLit = newLit($prc)

  result.parseArgs = quote do:
    if not verifyArgs(`argsTuple`, `kwargsDict`, `argsLen`, `argsLenReq`, `argNames`, `nameLit`):
      return PPyObject(nil)
    `parseArgsStmts`

  result.call = origCall

macro callNimProcWithPythonArgs(prc: typed, argsTuple: PPyObject, kwargsDict: PPyObject): PPyObject =
  let (parseArgs, call) = makeCallNimProcWithPythonArgs(prc, prc.getFormalParams, argsTuple, kwargsDict)
  result = quote do:
    `parseArgs`
    try:
      nimValueToPy(`call`)
    except Exception as e:
      pythonException(e)

type NimPyProcBase* {.inheritable, pure.} = ref object
  c: proc(args, kwargs: PPyObject, p: NimPyProcBase): PPyObject {.cdecl.}

proc callNimProc(self, args, kwargs: PPyObject): PPyObject {.cdecl.} =
  updateStackBottom()
  let np = cast[NimPyProcBase](pyLib.PyCapsule_GetPointer(self, nil))
  np.c(args, kwargs, np)

proc nimProcToPy[T](o: T): PPyObject =
  var md {.global.}: PyMethodDef
  if md.ml_name.isNil:
    md.ml_name = "anonymous"
    md.ml_flags = Py_MLFLAGS_VARARGS or Py_MLFLAGS_KEYWORDS
    md.ml_meth = callNimProc

  type NimProcS[T] = ref object of NimPyProcBase
    p: T

  proc doCall(args: PPyObject, kwargs: PPyObject, p: NimPyProcBase): PPyObject {.cdecl.} =
    var anonymous: T
    anonymous = cast[NimProcS[T]](p).p
    callNimProcWithPythonArgs(anonymous, args, kwargs)

  let np = NimProcS[T](p: o, c: doCall)
  let self = newPyCapsule(np)
  result = pyLib.PyCFunction_NewEx(addr md, self, nil)
  decRef self

proc makeProcWrapper(name, prc: NimNode): NimNode =
  let argsIdent = newIdentNode("args")
  let kwargsIdent = newIdentNode("kwargs")
  let (parseArgs, call) = makeCallNimProcWithPythonArgs(prc.name, prc.getFormalParams, argsIdent, kwargsIdent)
  result = quote do:
    proc `name`(self, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.cdecl.} =
      updateStackBottom()
      # Prevent inlining (See #67)
      proc noinline(`argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.nimcall.} =
        `parseArgs`
        try:
          nimValueToPy(`call`)
        except Exception as e:
          pythonException(e)
      var p {.volatile.}: proc(a, kwg: PPyObject): PPyObject {.nimcall.} = noinline
      p(`argsIdent`, `kwargsIdent`)

proc newPyIterator(typ: PyTypeObject, it: iterator(): PPyObject): PPyObject =
  result = cast[PPyObject](typ.tp_alloc(typ, 0))
  if result.isNil: return # Is exception needed here??
  let io = result.to(PyIteratorObj)
  io.iRef = PyIterRef(iter: it)
  GC_ref(io.iRef)

proc makeIteratorConstructor(name, prc: NimNode): NimNode =
  let argsIdent = newIdentNode("args")
  let kwargsIdent = newIdentNode("kwargs")
  let (parseArgs, call) = makeCallNimProcWithPythonArgs(prc.name, prc.getFormalParams, argsIdent, kwargsIdent)

  result = quote do:
    proc `name`(self: PyTypeObject, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.cdecl.} =
      updateStackBottom()
      # Prevent inlining (See #67)
      proc noinline(self: PyTypeObject, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.nimcall.} =
        `parseArgs`
        newPyIterator self, iterator(): PPyObject =
          for i in `call`:
            yield nimValueToPy(i)
          yield nil
      var p {.volatile.}: proc(s: PyTypeObject, a, kwg: PPyObject): PPyObject {.nimcall.} = noinline
      p(self, `argsIdent`, `kwargsIdent`)

proc callObjectRaw(o: PyObject, args: varargs[PPyObject, toPyObjectArgument]): PPyObject

template objToNimAux(res: untyped) =
  when declared(result):
    pyObjToNim(res, result)

macro pyObjToProcAux(o: PyObject, T: type): untyped =
  result = newProc(procType = nnkLambda)
  let inst = T.getTypeInst()
  if inst.len < 2 or inst.kind != nnkBracketExpr or inst[1].kind != nnkProcTy:
    echo "Unexpected closure type AST: ", treeRepr(inst)
    assert(false)
  result.params = T.getTypeInst[1][0]
  let theCall = newCall(bindSym"callObjectRaw", o)
  for a in inst[1].getFormalParams.arguments:
    theCall.add(a.name)
  result.body = quote do:
    let res = `theCall`
    objToNimAux(res)
    decRef res

proc pyObjToProc[T](o: PPyObject, v: var T) =
  if cast[pointer](o) == cast[pointer](pyLib.Py_None):
    v = nil
  else:
    let o = newPyObject(o)
    v = pyObjToProcAux(o, T)

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

  if prc.kind == nnkIteratorDef:
    procIdent = newIdentNode($procIdent & "Py_newIter")
    result.add(makeIteratorConstructor(procIdent, prc))
    result.add(newCall(bindSym"addIterator", newIdentNode("gPythonLocalModuleDesc"), newLit(procName), comment, procIdent))
  else:
    if wrap:
      procIdent = newIdentNode($procIdent & "Py_wrapper")
      result.add(makeProcWrapper(procIdent, prc))

    result.add(newCall(bindSym"addMethod", newIdentNode("gPythonLocalModuleDesc"), newLit(procName), comment, procIdent))
  # echo "procname: ", procName
  # echo repr result

macro exportpyAux(prc: untyped, modulename, procName: static[string], wrap: static[bool]): untyped =
  exportProc(prc, modulename, procName, wrap)

template exportpyAuxAux(prc: untyped{nkProcDef|nkFuncDef|nkIteratorDef}, procName: static[string]) =
  declarePyModuleIfNeeded()
  exportpyAux(prc, instantiationInfo().filename, procName, true)

template exportpyraw*(prc: untyped) =
  declarePyModuleIfNeeded()
  exportpyAux(prc, instantiationInfo().filename, nil, false)

# template exportpyIdent(i: typed, exportName: static[string]) =
#   discard

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
  #   result = newCall(bindSym"exportpyIdent", procDef, newLit(procName))
  # else:
  expectKind(procDef, {nnkProcDef, nnkFuncDef, nnkIteratorDef})
  result = newCall(bindSym"exportpyAuxAux", procDef, newLit(procName))

template addType(m: var PyModuleDesc, T: typed) =
  block:
    const name = astToStr(T)
    m.types.setLen(m.types.len + 1)
    m.types[^1].name = static(cstring(name))
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
  when T is void:
    discard
  else:
    pyObjToNim(v.rawPyObj, result)

proc toJson*(v: PyObject): JsonNode {.inline.} = pyObjToJson(v.rawPyObj)

proc callObjectAux(callable: PPyObject, args: openarray[PPyObject], kwargs: openarray[PyNamedArg] = []): PPyObject =
  let argTuple = pyLib.PyTuple_New(args.len)
  for i, v in args:
    assert(not v.isNil, "nimpy internal error v.isNil")
    discard pyLib.PyTuple_SetItem(argTuple, i, v)
    # No decRef here. PyTuple_SetItem "steals" the reference to v

  var argDict: PPyObject = nil
  if kwargs.len != 0:
    argDict = pyLib.PyDict_New()
    for v in kwargs:
      assert(not v.obj.isNil, "nimpy internal error v.obj.isNil")
      discard pyLib.PyDict_SetItemString(argDict, v.name, v.obj)
      decRef(v.obj)

  result = pyLib.PyObject_Call(callable, argTuple, argDict)
  decRef argTuple
  if not argDict.isNil: decRef(argDict)

proc callMethodAux(o: PyObject, name: cstring, args: openarray[PPyObject], kwargs: openarray[PyNamedArg] = []): PPyObject =
  let callable = pyLib.PyObject_GetAttrString(o.rawPyObj, name)
  if callable.isNil:
    raise newException(Exception, "No callable attribute: " & $name)
  result = callObjectAux(callable, args, kwargs)
  decRef callable
  if unlikely result.isNil: raisePythonError()

proc callObject*(o: PyObject, args: varargs[PPyObject, toPyObjectArgument]): PyObject {.inline.} =
  let res = callObjectAux(o.rawPyObj, args)
  if unlikely res.isNil: raisePythonError()
  newPyObjectConsumingRef(res)

proc callObjectRaw(o: PyObject, args: varargs[PPyObject, toPyObjectArgument]): PPyObject =
  result = callObjectAux(o.rawPyObj, args)
  if unlikely result.isNil: raisePythonError()

proc callMethod*(o: PyObject, name: cstring, args: varargs[PPyObject, toPyObjectArgument]): PyObject {.inline.} =
  newPyObjectConsumingRef(callMethodAux(o, name, args))

proc callMethod*(o: PyObject, ResultType: typedesc, name: cstring, args: varargs[PPyObject, toPyObjectArgument]): ResultType {.inline.} =
  let res = callMethodAux(o, name, args)
  pyObjToNim(res, result)
  decRef res

proc getAttr*(o: PyObject, name: cstring): PyObject =
  let r = pyLib.PyObject_GetAttrString(o.rawPyObj, name)
  if not r.isNil:
    result = newPyObjectConsumingRef(r)

proc getProperty*(o: PyObject, name: cstring): PyObject {.deprecated, inline.} = getAttr(o, name)

proc setAttr*(o: PyObject, name: cstring, value: PyObject) =
  let r = pyLib.PyObject_SetAttrString(o.rawPyObj, name, value.rawPyObj)
  if unlikely r != 0: raisePythonError()

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
  getAttr(o, astToStr(field))

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

proc `==`*(a, b: PyObject): bool =
  if a.isNil and b.isNil:
    true
  elif (not a.isNil) and (not b.isNil):
    pyLib.PyObject_RichCompareBool(a.rawPyObj, b.rawPyObj, Py_EQ) == 1
  else:
    false
