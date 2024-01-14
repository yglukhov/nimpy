import dynlib, macros, os, strutils, typetraits, tables, json,
  nimpy/[py_types, py_utils, nim_py_marshalling, py_nim_marshalling]

import nimpy/py_lib as lib

export nim_py_marshalling, py_nim_marshalling

when defined(gcDestructors):
  type PyObject* = object
    rawPyObj: PPyObject
else:
  type PyObject* = ref object
    rawPyObj: PPyObject

when not declared(AssertionDefect):
  type AssertionDefect = AssertionError

type
  PyNimObject {.inheritable.} = ref object
    py_extra_dont_use: PyObject_HEAD_EXTRA
    py_object: PyObjectObj

  PyNimObjectExperimental* = PyNimObject

type
  PyModuleDesc = object
    name: cstring
    doc: cstring
    methods: seq[PyMethodDef]
    types: seq[ptr PyTypeDesc]
    iterators: seq[PyIteratorDesc]

  PyIteratorDesc = object
    name: cstring
    doc: cstring
    newFunc: Newfunc

  PyTypeDesc = object
    name: cstring
    doc: cstring
    newFunc: Newfunc
    methods: seq[PyMethodDef]
    members: seq[PyMemberDef]
    origSize: int
    pyType: PyTypeObject

  PyIterRef = ref object
    iter: iterator(): PPyObject

  PyIteratorObj = object of PyObjectVarHeadObj
    iRef: PyIterRef

  PyNamedArg = tuple
    name: cstring
    obj: PPyObject


when defined(gcDestructors):
  proc isNil*(p: PyObject): bool {.inline.} = p.rawPyObj.isNil

  proc `=destroy`*(p: var PyObject) =
    if not p.rawPyObj.isNil:
      decRef p.rawPyObj
      p.rawPyObj = nil

  proc `=copy`*(dst: var PyObject, src: PyObject) =
    if pointer(dst.rawPyObj) != pointer(src.rawPyObj):
      if not src.rawPyObj.isNil:
        incRef src.rawPyObj
      `=destroy`(dst)
      dst.rawPyObj = src.rawPyObj

  converter nilToPyObject*(_: typeof(nil)): PyObject {.inline.} = discard

proc privateRawPyObj*(p: PyObject): PPyObject {.inline.} =
  # Don't use this
  p.rawPyObj

var curModuleDef: ptr PyModuleDesc

proc registerMethod(name, doc: cstring, f: PyCFunctionWithKeywords) =
  assert(not curModuleDef.isNil)
  let def = PyMethodDef(ml_name: name, ml_meth: f, ml_flags: Py_MLFLAGS_VARARGS or Py_MLFLAGS_KEYWORDS,
              ml_doc: doc)
  curModuleDef[].methods.add(def)

proc registerIterator(name, doc: cstring, newFunc: Newfunc) =
  assert(not curModuleDef.isNil)
  curModuleDef[].iterators.add(PyIteratorDesc(name: name, doc: doc, newFunc: newFunc))

proc newPyNimObject[T](typ: PyTypeObject, args, kwds: PPyObject): PPyObject {.cdecl.}

proc pTypeDesc(T: typedesc): ptr PyTypeDesc =
  var t {.global.}: PyTypeDesc
  if t.newFunc.isNil: # Not inited
    t.name = static(cstring($T))
    t.newFunc = newPyNimObject[T]
    t.origSize = sizeof(T)
  addr t

proc initPyNimObjectWithPyType(o: PyNimObject, typ: PyTypeObject) =
  assert(typ != nil)
  o.py_object.ob_type = typ
  GC_ref(o)

proc pyNimObjectToPyObject[T: PyNimObject](o: T): PPyObject {.inline.} =
  inc o.py_object.ob_refcnt
  cast[PPyObject](addr o.py_object)

proc pyAlloc(sz: int): PPyObject {.inline.} =
  cast[PPyObject](alloc0(sz.uint + pyObjectStartOffset))

proc toNim(p: PPyObject, t: typedesc): t {.inline.} =
  cast[t](cast[uint](p) - uint(sizeof(PyObject_HEAD_EXTRA) + sizeof(pointer)))

proc freeNimObj(p: pointer) {.cdecl.} =
  raise newException(AssertionDefect, "Internal pynim error. Free called on Nim object.")

proc destructNimObj(o: PPyObject) {.cdecl.} =
  let n = toNim(o, PyNimObject)
  GC_unref(n)

proc strToPyObject(s: string): PPyObject {.gcsafe.} =
  var cs: cstring = s
  var ln = s.len.cint
  result = pyLib.Py_BuildValue("s#", cs, ln)
  if result.isNil:
    # Utf-8 decoding failed. Fallback to bytes.
    pyLib.PyErr_Clear()
    result = pyLib.Py_BuildValue("y#", cs, ln)

  assert(not result.isNil, "nimpy internal error converting string")

proc iterDescrGet(a, b, c: PPyObject): PPyObject {.cdecl.} =
  strToPyObject("nim iterator")

proc typDescrGet(a, b, c: PPyObject): PPyObject {.cdecl.} =
  strToPyObject("nim type")

proc defaultTPFLAGS(): culong =
  if pyLib.pythonVersion >= (3, 10, 0): 0 else: Py_TPFLAGS_DEFAULT_EXTERNAL

proc initPyNimObjectType[PyTypeObj](td: var PyTypeDesc) =
  assert(not pyLib.isNil)
  assert(td.pyType.isNil)

  let typ = pyAlloc(sizeof(PyTypeObj))
  let ty = typ.to(PyTypeObj)
  td.pyType = ty
  ty.tp_name = td.name

  # Nim objects have an m_type* in front, we're stripping that away for python,
  # so we're telling python that the size is less by one pointer
  ty.tp_basicsize = td.origSize.cint - sizeof(pointer).cint
  ty.tp_flags = defaultTPFLAGS()
  ty.tp_doc = td.doc
  ty.tp_new = td.newFunc
  ty.tp_free = freeNimObj
  ty.tp_dealloc = destructNimObj
  ty.tp_descr_get = typDescrGet

  if td.methods.len != 0:
    td.methods.add(PyMethodDef()) # Add sentinel
    ty.tp_methods = unsafeAddr td.methods[0]

  discard pyLib.PyType_Ready(cast[PyTypeObject](typ))
  incRef(typ)

proc nimValueToPy*[T: PyNimObject](o: T): PPyObject {.inline.} =
  if o.isNil:
    return newPyNone()

  if o.py_object.ob_type.isNil:
    let td = pTypeDesc(T)
    if td.pyType.isNil:
      initPyNimObjectType[PyTypeObject3Obj](td[])
      assert(not td.pyType.isNil)
    initPyNimObjectWithPyType(o, td.pyType)
  pyNimObjectToPyObject(o)

proc nimValueToPy*(v: PyObject): PPyObject {.inline.} =
  if v.isNil:
    newPyNone()
  else:
    assert(not v.rawPyObj.isNil, "nimpy internal error rawPyObj.isNil")
    incRef v.rawPyObj
    v.rawPyObj

proc nimExceptionToPy(e: ref Exception): PPyObject =
  if e of AssertionDefect:
    pyLib.PyExc_AssertionError
  elif e of DivByZeroDefect or e of FloatDivByZeroDefect:
    pyLib.PyExc_ZeroDivisionError
  else:
    pyLib.PyErr_NewException(cstring("nimpy" & "." & $(e.name)), pyLib.NimPyException, nil)

proc newPyNimObject[T](typ: PyTypeObject, args, kwds: PPyObject): PPyObject {.cdecl.} =
  let o = T()
  initPyNimObjectWithPyType(o, typ)
  pyNimObjectToPyObject(o)

var exportedTypeTable {.compileTime.} = initTable[string, int]()

proc getTypeIdxInModule(T: typedesc): int {.compileTime.} =
  exportedTypeTable.mgetOrPut($T, exportedTypeTable.len)

proc addTypedefToModuleDef(md: ptr PyModuleDesc, T: typedesc, idx: int) =
  assert(md.types.len == idx)
  md.types.add(pTypeDesc(T))

template registerTypeMethod(T: typedesc, name, doc: cstring, f: PyCFunctionWithKeywords) =
  when T isnot PyNimObjectExperimental:
    {.error: "Type " & $T & " is not a subclass of PyNimObjectExperimental, while trying to export type method " & $name & " because its first argument is named `self`"}
  assert(not curModuleDef.isNil)
  const typeIdx = getTypeIdxInModule(T)
  if typeIdx > curModuleDef.types.high: addTypedefToModuleDef(curModuleDef, T, typeIdx)
  curModuleDef.types[typeIdx].methods.add(PyMethodDef(ml_name: name, ml_meth: f, ml_flags: Py_MLFLAGS_VARARGS or Py_MLFLAGS_KEYWORDS,
              ml_doc: doc))

proc initPythonModuleDesc(m: var PyModuleDesc, name, doc: cstring) =
  m.name = name
  m.doc = doc

proc initCommon(m: var PyModuleDesc) =
  if pyLib.isNil:
    pyLib = loadPyLibFromThisProcess()
  m.methods.add(PyMethodDef()) # Add sentinel

proc destructNimIterator(o: PPyObject) {.cdecl.} =
  let n = to(o, PyIteratorObj)
  GC_unref(n.iRef)

when compileOption("threads"):
  var gcInited {.threadVar.}: bool

proc updateStackBottom() {.inline.} =
  when not defined(gcDestructors):
    var a {.volatile.}: int
    nimGC_setStackBottom(cast[pointer](cast[uint](addr a)))
    when compileOption("threads") and not compileOption("tlsEmulation") and not defined(useNimRtl):
      if not gcInited:
        gcInited = true
        setupForeignThreadGC()

proc pythonException(e: ref Exception): PPyObject =
  let err = nimExceptionToPy(e)
  let errMsg: string =
    when compileOption("stackTrace"):
      "Unexpected error encountered: " & e.msg & "\nstack trace: (most recent call last)\n" & e.getStackTrace()
    else:
      "Unexpected error encountered: " & e.msg
  pyLib.PyErr_SetString(err, errmsg.cstring)

proc iterNext(i: PPyObject): PPyObject {.cdecl.} =
  updateStackBottom()
  try:
    i.to(PyIteratorObj).iRef.iter()
  except Exception as e:
    pythonException(e)

proc initModuleTypes[PyTypeObj](p: PPyObject, m: var PyModuleDesc) =
  for i in 0 ..< m.types.len:
    initPyNimObjectType[PyTypeObj](m.types[i][])
    let typ = cast[PPyObject](cast[uint](m.types[i].pyType) - pyObjectStartOffset)
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
    ty.tp_flags = defaultTPFLAGS()
    ty.tp_doc = m.iterators[i].doc
    ty.tp_new = m.iterators[i].newFunc
    ty.tp_free = freeNimObj
    ty.tp_dealloc = destructNimIterator
    ty.tp_iternext = cast[Iternextfunc](iterNext)
    ty.tp_iter = selfIter
    ty.tp_descr_get = iterDescrGet

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

var registeredModuleNames {.compileTime.}: seq[string]

proc containsOrIncl[T](s: var seq[T], v: T): bool =
  result = v in s
  if not result:
    s.add(v)

template declareModuleIfNeeded(name, doc: static[cstring]) =
  when not containsOrIncl(registeredModuleNames, name):
    block:
      var moduleDesc {.global.}: PyModuleDesc
      initPythonModuleDesc(moduleDesc, name, doc)
      {.push stackTrace: off.}
      proc py2init() {.exportc: "init" & name, dynlib.} =
        initModule2(moduleDesc)

      proc py3init(): PPyObject {.exportc: "PyInit_" & name, dynlib.} =
        initModule3(moduleDesc)

      proc getModule(): ptr PyModuleDesc {.exportc: "_nimpyModuleDesc_" & name.} =
        addr moduleDesc
      {.pop.}

      registerExportedModule(name, cast[pointer](py2Init), cast[pointer](py3Init))

template setCurrentPyModule(name, doc: static[cstring]) =
  declareModuleIfNeeded(name, doc)
  block:
    proc getModule(): ptr PyModuleDesc {.importc: "_nimpyModuleDesc_" & name.}
    curModuleDef = getModule()
  when not declared(gPythonLocalModuleDescDeclared):
    const gPythonLocalModuleDescDeclared {.used, inject.} = true

template declarePyModuleIfNeeded() =
  when not declared(gPythonLocalModuleDescDeclared):
    const moduleName = splitFile(instantiationInfo(0).filename).name
    setCurrentPyModule(moduleName, "")

template pyExportModuleName*(n: static[cstring]) {.deprecated: "Use pyExportModule instead".} =
  setCurrentPyModule(n, "")

template pyExportModule*(name: static[cstring] = "", doc: static[cstring] = "") =
  setCurrentPyModule(name, doc)

################################################################################
################################################################################
################################################################################

proc toString*(b: RawPyBuffer): string =
  if not b.buf.isNil:
    let ln = b.len
    result = newString(ln)
    if ln != 0:
      copyMem(addr result[0], b.buf, ln)

when not defined(gcDestructors):
  proc finalizePyObject(o: PyObject) =
    decRef o.rawPyObj

proc newPyObjectConsumingRef(o: PPyObject): PyObject =
  assert(not o.isNil, "internal error")
  when not defined(gcDestructors):
    result.new(finalizePyObject)
  result.rawPyObj = o

proc newPyObject(o: PPyObject): PyObject =
  incRef o
  newPyObjectConsumingRef(o)

proc pyValueToNim*(v: PPyObject, o: var PyObject) {.inline.} =
  o = newPyObject(v)

proc pyValueToNim*[T: PyNimObject](v: PPyObject, o: var T) =
  if cast[pointer](v) == cast[pointer](pyLib.Py_None):
    o = nil
  else:
    let typ = cast[PyTypeObject]((cast[ptr PyObjectObj](v)).ob_type)
    if typ.tp_descr_get == typDescrGet: # Very basic check if the object is indeed a nim object
      o = T(toNim(v, PyNimObject))
    else:
      pyValueToNimRaiseConversionError($T)

proc pyValueToNim*[T: ref](v: PPyObject, o: var T) =
  if cast[pointer](v) == cast[pointer](pyLib.Py_None):
    o = nil
  else:
    pyValueToNimConversionTypeCheck(pyLib.PyCapsule_Type)
    o = cast[T](pyLib.PyCapsule_GetPointer(v, nil))

proc refCapsuleDestructor(c: PPyObject) {.cdecl.} =
  let o = pyLib.PyCapsule_GetPointer(c, nil)
  GC_unref(cast[ref int](o))

proc newPyCapsule[T](v: ref T): PPyObject =
  GC_ref(v)
  pyLib.PyCapsule_New(cast[pointer](v), nil, refCapsuleDestructor)

proc nimValueToPy*(v: ref): PPyObject =
  if v.isNil:
    newPyNone()
  else:
    newPyCapsule(v)

iterator items*(o: PyObject): PyObject =
  for i in o.rawPyObj.rawItems:
    yield newPyObjectConsumingRef(i)

proc pyDictHasKey(o: PPyObject, k: cstring): bool =
  let pk = pyLib.PyUnicode_FromString(k)
  result = pyLib.PyDict_Contains(o, pk) == 1
  decRef pk

proc `==`(o: PPyObject, k: cstring): bool =
  if pyLib.PyUnicode_CompareWithASCIIString.isNil:
    result = pyLib.PyString_AsString(o) == k
  else:
    result = pyLib.PyUnicode_CompareWithASCIIString(o, k) == 0

proc `$`*(o: PyObject): string {.inline.} = pyValueStringify(o.rawPyObj)

proc getPyArg(argTuple, argDict: PPyObject, argIdx: int, argName: cstring): PPyObject =
  # argTuple can never be nil
  if argIdx < pyLib.PyTuple_Size(argTuple):
    result = pyLib.PyTuple_GetItem(argTuple, argIdx)
  if result.isNil and not argDict.isNil:
    result = pyLib.PyDict_GetItemString(argDict, argName)

proc parseArg[T](argTuple, kwargsDict: PPyObject, argIdx: int, argName: cstring, result: var T) =
  let arg = getPyArg(argTuple, kwargsDict, argIdx, argName)
  if not arg.isNil:
    pyValueToNim(arg, result)
  # TODO: What do we do if arg is nil???

template raisePyException(tp, msg: untyped): untyped =
  pyLib.PyErr_SetString(tp, cstring(msg))
  return false

proc verifyArgs(argTuple, kwargsDict: PPyObject, argsLen, argsLenReq: int, argNames: openArray[cstring], funcName: string): bool =
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

  for i in nargs ..< argsLen:
    if i < argsLenReq and nkwargs != 0: # we get required kwarg
      if not pyDictHasKey(kwargsDict, argNames[i]):
        raisePyException(pyLib.PyExc_TypeError, funcName & "() missing 1 required positional argument: " & $argNames[i])
      else:
        dec nkwarg_left
    elif nkwargs != 0: # we get optional kwarg
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
        var kStr: string
        pyValueToNim(k, kStr)
        decRef k
        raisePyException(pyLib.PyExc_TypeError, funcName & "() got an unexpected keyword argument " & kStr)

template seqTypeForOpenarrayType[T](t: type openArray[T]): typedesc = seq[T]
template valueTypeForArgType(t: typedesc): typedesc =
  when t is openArray:
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

proc stripSinkFromArgType(t: NimNode): NimNode =
  result = t
  if result.kind == nnkBracketExpr and result.len == 2 and result[0].kind == nnkSym and $result[0] == "sink":
    result = result[1]

iterator arguments(formalParams: NimNode): tuple[idx: int, name, typ, default: NimNode] =
  formalParams.expectKind(nnkFormalParams)
  var iParam = 0
  for i in 1 ..< formalParams.len:
    let pp = formalParams[i]
    for j in 0 .. pp.len - 3:
      yield (iParam, pp[j], copyNimTree(stripSinkFromArgType(pp[^2])), pp[^1])
      inc iParam

proc makeCallNimProcWithPythonArgs(prc, formalParams, argsTuple, kwargsDict: NimNode, selfArg: NimNode = nil): tuple[parseArgs, call: NimNode] =
  let
    pyValueVarSection = newNimNode(nnkVarSection)
    parseArgsStmts = newNimNode(nnkStmtList)

  let
    origCall = newCall(prc)

  var
    numArgs = 0
    numArgsReq = 0
    argNames = newNimNode(nnkBracket)

  let extraArg = if selfArg == nil: 0 else: 1

  for a in formalParams.arguments:
    let argIdent = newIdentNode("arg" & $a.idx & $a.name)
    let argName = $a.name

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

    if numArgs == 0 and selfArg != nil:
      parseArgsStmts.add(newCall(bindSym"pyValueToNim", selfArg, argIdent))
    else:
      parseArgsStmts.add(newCall(bindSym"parseArg", argsTuple, kwargsDict,
                    newLit(a.idx - extraArg), newLit(argName), argIdent))
      argNames.add(newCall(ident"cstring", newLit(argName)))
    origCall.add(argIdent)
    inc numArgs

  let
    argsLen = newLit(numArgs)
    argsLenReq = newLit(numArgsReq - extraArg)
    nameLit = newLit($prc)

  result.parseArgs = quote do:
    if not verifyArgs(`argsTuple`, `kwargsDict`, `argsLen`, `argsLenReq`, `argNames`, `nameLit`):
      return PPyObject(nil)
    `pyValueVarSection`
    try:
      `parseArgsStmts`
    except CatchableError as e:
      pyLib.PyErr_SetString(pyLib.PyExc_TypeError, cstring(e.msg))
      return PPyObject(nil)

  result.call = origCall

proc nimValueOrVoidToPy[T](v: T): PPyObject =
  when T is void:
    newPyNone()
  else:
    nimValueToPy(v)

macro callNimProcWithPythonArgs(prc: typed, argsTuple: PPyObject, kwargsDict: PPyObject): PPyObject =
  let (parseArgs, call) = makeCallNimProcWithPythonArgs(prc, prc.getFormalParams, argsTuple, kwargsDict)
  result = quote do:
    `parseArgs`
    try:
      nimValueOrVoidToPy(`call`)
    except Exception as e:
      pythonException(e)

type NimPyProcBase* {.inheritable, pure.} = ref object
  c: proc(args, kwargs: PPyObject, p: NimPyProcBase): PPyObject {.cdecl.}

proc callNimProc(self, args, kwargs: PPyObject): PPyObject {.cdecl.} =
  updateStackBottom()
  let np = cast[NimPyProcBase](pyLib.PyCapsule_GetPointer(self, nil))
  np.c(args, kwargs, np)

proc nimValueToPy*[T: proc](o: T): PPyObject =
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

proc makeProcWrapper(name, prc: NimNode, isMethod: bool): NimNode =
  let argsIdent = newIdentNode("args")
  let kwargsIdent = newIdentNode("kwargs")
  if isMethod:
    let selfIdent = newIdentNode("self")
    let (parseArgs, call) = makeCallNimProcWithPythonArgs(prc.name, prc.getFormalParams, argsIdent, kwargsIdent, selfIdent)
    result = quote do:
      proc `name`(`selfIdent`, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.cdecl.} =
        updateStackBottom()
        # Prevent inlining (See #67)
        proc noinline(`selfIdent`, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.nimcall, stackTrace: off.} =
          `parseArgs`
          try:
            nimValueOrVoidToPy(`call`)
          except Exception as e:
            pythonException(e)
        var p {.volatile.}: proc(s, a, kwg: PPyObject): PPyObject {.nimcall.} = noinline
        p(`selfIdent`, `argsIdent`, `kwargsIdent`)
  else:
    let (parseArgs, call) = makeCallNimProcWithPythonArgs(prc.name, prc.getFormalParams, argsIdent, kwargsIdent)
    result = quote do:
      proc `name`(self, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.cdecl.} =
        updateStackBottom()
        # Prevent inlining (See #67)
        proc noinline(`argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.nimcall, stackTrace: off.} =
          `parseArgs`
          try:
            nimValueOrVoidToPy(`call`)
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
      proc noinline(self: PyTypeObject, `argsIdent`, `kwargsIdent`: PPyObject): PPyObject {.nimcall, stackTrace: off.} =
        `parseArgs`
        newPyIterator self, iterator(): PPyObject =
          for i in `call`:
            yield nimValueToPy(i)
          yield nil
      var p {.volatile.}: proc(s: PyTypeObject, a, kwg: PPyObject): PPyObject {.nimcall.} = noinline
      p(self, `argsIdent`, `kwargsIdent`)

proc callObjectRaw(o: PyObject, args: varargs[PPyObject, toPyObjectArgument]): PPyObject

template objToNimResult(res: untyped) =
  when declared(result):
    pyValueToNim(res, result)

macro pyObjToProcAux(o: PyObject, T: type): untyped =
  result = newProc(procType = nnkLambda)
  let inst = T.getTypeInst()
  if inst.len < 2 or inst.kind != nnkBracketExpr or inst[1].kind != nnkProcTy:
    echo "Unexpected closure type AST: ", treeRepr(inst)
    assert(false)

  let params = inst[1][0]
  let newParams = newNimNode(nnkFormalParams)
  let theCall = newCall(bindSym"callObjectRaw", o)
  newParams.add(params[0])
  for a in params.arguments:
    let p = ident($a.name)
    newParams.add(newIdentDefs(p, a.typ))
    theCall.add(p)

  result.params = newParams
  result.body = quote do:
    let res = `theCall`
    objToNimResult(res)
    decRef res

proc pyValueToNim*[T: proc {.closure.}](o: PPyObject, v: var T) =
  if cast[pointer](o) == cast[pointer](pyLib.Py_None):
    v = nil
  else:
    let o = newPyObject(o)
    v = pyObjToProcAux(o, T)

proc exportProc(prc: NimNode, procName: string, wrap: bool): NimNode =
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

  let isMethod = prc.params.len > 1 and $prc.params[1][0] == "self"

  if prc.kind == nnkIteratorDef:
    procIdent = newIdentNode($procIdent & "Py_newIter")
    result.add(makeIteratorConstructor(procIdent, prc))
    result.add(newCall(bindSym"registerIterator", newLit(procName), comment, procIdent))
  else:
    if wrap:
      procIdent = genSym(nskProc, $procIdent & "Py_wrapper")
      result.add(makeProcWrapper(procIdent, prc, isMethod))

    if isMethod:
      var typ = prc.params[1][^2]
      typ = newCall("type", typ) # Workaround nim bug???
      result.add(newCall(bindSym"registerTypeMethod", typ, newLit(procName), comment, procIdent))
    else:
      result.add(newCall(bindSym"registerMethod", newLit(procName), comment, procIdent))
  # echo "procname: ", procName
  # echo repr result

macro exportpyAux(prc: untyped, procName: static[string], wrap: static[bool]): untyped =
  exportProc(prc, procName, wrap)

template exportpyAuxAux(prc: untyped{nkProcDef|nkFuncDef|nkIteratorDef}, procName: static[string]) =
  declarePyModuleIfNeeded()
  exportpyAux(prc, procName, true)

template exportpyraw*(prc: untyped) =
  declarePyModuleIfNeeded()
  exportpyAux(prc, nil, false)

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
    pyValueToNim(v.rawPyObj, result)

proc callObjectAux(callable: PPyObject, args: openArray[PPyObject], kwargs: openArray[PyNamedArg] = []): PPyObject =
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

proc callMethodAux(o: PyObject, name: cstring, args: openArray[PPyObject], kwargs: openArray[PyNamedArg] = []): PPyObject =
  let callable = pyLib.PyObject_GetAttrString(o.rawPyObj, name)
  if callable.isNil:
    raise newException(ValueError, "No callable attribute: " & $name)
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
  pyValueToNim(res, result)
  decRef res

proc getAttr*(o: PyObject, name: cstring): PyObject =
  let r = pyLib.PyObject_GetAttrString(o.rawPyObj, name)
  if unlikely r.isNil:
    raisePythonError()
    # this would cause corruptions with try/except: raise newException(ValueError, "object has no attribute: " & $name)
  else:
    result = newPyObjectConsumingRef(r)

proc setAttr*(o: PyObject, name: cstring, value: PyObject) =
  let r = pyLib.PyObject_SetAttrString(o.rawPyObj, name, value.rawPyObj)
  if unlikely r != 0: raisePythonError()

proc setAttrAux(o: PyObject, name: cstring, v: PPyObject) =
  let r = pyLib.PyObject_SetAttrString(o.rawPyObj, name, v)
  decRef v
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

template `.=`*(o: PyObject, field: untyped, value: untyped) =
  when value is PyObject:
    setAttr(o, astToStr(field), value)
  else:
    setAttrAux(o, astToStr(field), toPyObjectArgument(value))

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
  let r = pyLib.PyEval_GetGlobals()
  if not r.isNil:
    result = newPyObject(r)

proc pyLocals*(): PyObject =
  initPyLibIfNeeded()
  let r = pyLib.PyEval_GetLocals()
  if not r.isNil:
    result = newPyObject(r)

proc dir*(v: PyObject): seq[string] =
  let lst = pyLib.PyObject_Dir(v.rawPyObj)
  pyValueToNim(lst, result)
  decRef lst

proc pyBuiltinsModule*(): PyObject =
  initPyLibIfNeeded()
  pyImport(if pyLib.pythonVersion.major == 3: static(cstring("builtins")) else: static(cstring("__builtin__")))

proc `==`*(a, b: PyObject): bool =
  if pointer(a.rawPyObj) == pointer(b.rawPyObj):
    true
  elif (not a.isNil) and (not b.isNil):
    pyLib.PyObject_RichCompareBool(a.rawPyObj, b.rawPyObj, Py_EQ) == 1
  else:
    false

proc super*(self: PyObject): PyObject {.gcsafe.} =
  let self = self.rawPyObj
  let superArgs = pyLib.PyTuple_New(2)

  let selfTyp = cast[PPyObject](self.to(PyObjectObj).ob_type)
  incRef(selfTyp)
  discard pyLib.PyTuple_SetItem(superArgs, 0, selfTyp)

  incRef(self)
  discard pyLib.PyTuple_SetItem(superArgs, 1, self)

  let res = pyLib.PyType_GenericNew(pyLib.PySuper_Type, superArgs, nil)
  discard cast[PPyObject](res.to(PyObjectObj).ob_type).to(PyTypeObject3Obj).tp_init(res, superArgs, nil)
  decRef(superArgs)

  newPyObjectConsumingRef(res)

proc makePyDict(kv: varargs[(string, PPyObject)]): PPyObject =
  result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
  for (k, v) in kv:
    let ret = pyLib.PyDict_SetItemString(result, cstring(k), v)
    decRef v
    if ret != 0:
      cannotSerializeErr(k)

macro toPyDictRaw(a: untyped): PPyObject =
  if a.kind == nnkTableConstr:
    result = newCall(bindSym"makePyDict")
    for ai in a:
      let key = ai[0]
      let val = ai[1]
      result.add(newTree(nnkTupleConstr, key, newCall(bindSym"toPyObjectArgument", val)))
  else:
    result = newCall(bindSym"nimValueToPyDict", a)

template toPyDict*(a: untyped): PyObject =
  newPyObjectConsumingRef(toPyDictRaw(a))

proc pyDict*(): PyObject =
  newPyObjectConsumingRef(toPyDictRaw(()))

################################################################################
################################################################################
################################################################################
# Deprecated API
proc getProperty*(o: PyObject, name: cstring): PyObject {.deprecated: "Use getAttr instead", inline.} = getAttr(o, name)
template toDict*(a: untyped): PPyObject {.deprecated: "Use toPyDict instead".} = toPyDictRaw(a)
proc toJson*(v: PyObject): JsonNode {.deprecated: "Use myObj.to(JsonNode) instead".} = v.to(JsonNode)
