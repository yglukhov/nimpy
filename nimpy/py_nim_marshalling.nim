import std/[json, complex, tables, strutils]
import ./py_types, ./py_utils
import ./py_lib as lib

type
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

proc pyValueToNimRaiseConversionError*(toType: string) =
  raise newException(ValueError, "Cannot convert python object to " & toType)

proc clearAndRaiseConversionError(toType: string) =
  pyLib.PyErr_Clear()
  pyValueToNimRaiseConversionError(toType)

template conversionErrorCheck() =
  if unlikely(not pyLib.PyErr_Occurred().isNil):
    clearAndRaiseConversionError($typeof(o))

template pyValueToNimConversionTypeCheck*(what: PyTypeObject) =
  if not checkObjSubclass(v, what):
    pyValueToNimRaiseConversionError($typeof(o))

proc pyValueToNim*[T: uint8|uint16|uint32|int|int8|int16|int32|int64|char|byte](v: PPyObject, o: var T) {.inline.} =
  let ll = pyLib.PyLong_AsLongLong(v)
  if ll == -1: conversionErrorCheck()
  o = T(ll)

proc pyValueToNim*[T: uint|uint64](v: PPyObject, o: var T) {.inline.} =
  when T is uint and sizeof(uint) < sizeof(uint64):
    var so: uint32
    pyValueToNim(v, so)
    o = so
  else:
    let lo = pyLib.PyNumber_Long(v)
    if unlikely lo.isNil:
      conversionErrorCheck()
      assert(false, "Unreachable")
    let ll = pyLib.PyLong_AsUnsignedLongLong(lo)
    decRef lo
    if ll == uint64.high: conversionErrorCheck()
    o = T(ll)

proc pyValueToNim*[T: float|float32|float64](v: PPyObject, o: var T) {.inline.} =
  o = T(pyLib.PyFloat_AsDouble(v))
  if o == -1.0'f64: conversionErrorCheck()

proc pyValueToNim*(v: PPyObject, o: var bool) {.inline.} =
  o = bool(pyLib.PyObject_IsTrue(v))

proc pyValueToNim*(v: PPyObject, o: var PPyObject) {.inline.} =
  o = v

proc pyValueToNim*(v: PPyObject, o: var Complex) {.inline.} =
  pyValueToNimConversionTypeCheck(pyLib.PyComplex_Type)
  if unlikely pyLib.PyComplex_AsCComplex.isNil:
    o.re = pyLib.PyComplex_RealAsDouble(v)
    o.im = pyLib.PyComplex_ImagAsDouble(v)
  else:
    let vv = pyLib.PyComplex_AsCComplex(v)
    when declared(Complex64):
      when o is Complex64:
        o = vv
      else:
        o.re = vv.re
        o.im = vv.im
    else:
      o = vv

proc pyValueToNim*(v: PPyObject, o: var string) {.inline.} =
  if unlikely(not pyStringToNim(v, o)):
    # Name the type that is unable to be converted.
    let typ = cast[PyTypeObject]((cast[ptr PyObjectObj](v)).ob_type)
    let errString = "Can't convert python obj of type '$1' to string"
    raise newException(ValueError, errString % [$typ.tp_name])

proc pyObjFillArray[T](o: PPyObject, getItem: proc(l: PPyObject, index: Py_ssize_t): PPyObject {.cdecl, gcsafe.}, v: var openarray[T]) {.inline.} =
  for i in 0 ..< v.len:
    pyValueToNim(getItem(o, i), v[i])
    # No DECREF. getItem returns borrowed ref.

proc getListOrTupleAccessors(o: PPyObject):
    tuple[getSize: proc(l: PPyObject): Py_ssize_t {.cdecl, gcsafe.},
      getItem: proc(l: PPyObject, index: Py_ssize_t): PPyObject {.cdecl, gcsafe.}] =
  if checkObjSubclass(o, pyLib.PyList_Type):
    result.getSize = pyLib.PyList_Size
    result.getItem = pyLib.PyList_GetItem
  elif checkObjSubclass(o, pyLib.PyTuple_Type):
    result.getSize = pyLib.PyTuple_Size
    result.getItem = pyLib.PyTuple_GetItem

proc pyValueToNim*[T](v: PPyObject, o: var seq[T]) =
  when T is byte:
    if checkObjSubclass(v, pyLib.PyBytes_Type):
      var sz: Py_ssize_t
      var pStr: ptr char
      if pyLib.PyBytes_AsStringAndSize(v, addr pStr, addr sz) == -1:
        pyValueToNimRaiseConversionError($typeof(o))
      o.setLen(sz)
      if sz != 0:
        copyMem(addr o[0], pStr, sz)
      return

  let (getSize, getItem) = getListOrTupleAccessors(v)
  if unlikely getSize.isNil:
    pyValueToNimRaiseConversionError($typeof(o))

  let sz = int(getSize(v))
  assert(sz >= 0)
  o = newSeq[T](sz)
  pyObjFillArray(v, getItem, o)

proc pyValueToNim*[I: static[int], T](v: PPyObject, o: var array[I, T]) =
  when T is byte:
    if checkObjSubclass(v, pyLib.PyBytes_Type):
      var sz: Py_ssize_t
      var pStr: ptr char
      if pyLib.PyBytes_AsStringAndSize(v, addr pStr, addr sz) == -1 or sz != o.len:
        pyValueToNimRaiseConversionError($type(o))
      when o.len != 0:
        copyMem(addr o[0], pStr, sz)
      return

  let (getSize, getItem) = getListOrTupleAccessors(v)
  if not getSize.isNil:
    let sz = int(getSize(v))
    if sz == o.len:
      pyObjFillArray(v, getItem, o)
      return

  pyValueToNimRaiseConversionError($type(o))

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

proc pyValueStringify*(v: PPyObject): string =
  assert(not v.isNil)
  let s = pyLib.PyObject_Str(v)
  pyValueToNim(s, result)
  decRef s

proc pyObjToJson(o: PPyObject): JsonNode =
  let bType = o.baseType
  case bType
  of pbUnknown:
    if cast[pointer](o) == cast[pointer](pyLib.Py_None):
      result = newJNull()
    else:
    # unsupported means we just use string conversion
      result = %pyValueStringify(o)
  of pbLong:
    let typ = cast[PyTypeObject]((cast[ptr PyObjectObj](o)).ob_type)
    if typ == pylib.PyBool_Type:
      var x: bool
      pyValueToNim(o, x)
      result = %x
    else:
      var x: int
      pyValueToNim(o, x)
      result = %x
  of pbFloat:
    var x: float
    pyValueToNim(o, x)
    result = %x
  of pbComplex:
    when declared(Complex64):
      var x: Complex64
    else:
      var x: Complex

    pyValueToNim(o, x)
    result = %*{ "real" : x.re,
                 "imag" : x.im }
  of pbList, pbTuple:
    result = newJArray()
    for x in o.rawItems:
      result.add(pyObjToJson(x))
      decRef x

  of pbBytes, pbUnicode, pbString:
    result = % $pyValueStringify(o)
  of pbDict:
    # dictionaries are represented as `JObjects`, where the Python dict's keys
    # are stored as strings
    result = newJObject()
    for key in o.rawItems:
      let val = pyLib.PyDict_GetItem(o, key)
      result[pyValueStringify(key)] = pyObjToJson(val)
      decRef key
      # No DECREF for val here. PyDict_GetItem returns a borrowed ref.

  of pbObject: # not used, for objects currently end up as `pbUnknown`
    result = % pyValueStringify(o)
  of pbCapsule: # not used
    raise newException(ValueError, "Cannot store object of base type " &
      "`pbCapsule` in JSON.")

proc pyValueToNim*(v: PPyObject, o: var JsonNode) {.inline.} =
  o = pyObjToJson(v)

proc pyValueToNim*[T; U](v: PPyObject, o: var Table[T, U]) =
  ## call this either:
  ## - if you want to check whether T and U are valid types for
  ##   the python dict (i.e. to check whether all python types
  ##   are convertible to T and U)
  ## - you know the python dict conforms to T and U and you wish
  ##   to get a correct Nim table from that
  o = initTable[T, U]()
  let
    sz = int(pyLib.PyDict_Size(v))
    ks = pyLib.PyDict_Keys(v)
    vs = pyLib.PyDict_Values(v)
  for i in 0 ..< sz:
    var
      k: T
      v: U
    pyValueToNim(pyLib.PyList_GetItem(ks, i), k)
    pyValueToNim(pyLib.PyList_GetItem(vs, i), v)
    # PyList_GetItem # No DECREF. Returns borrowed ref.
    o[k] = v
  decRef ks
  decRef vs

proc pyValueToNim*[T: object](v: PPyObject, o: var T) =
  for k, vv in fieldPairs(o):
    let f = pyLib.PyDict_GetItemString(v, k)
    if not f.isNil:
      pyValueToNim(f, vv)
    # No DECREF here. PyDict_GetItemString returns a borrowed ref.

proc pyValueToNim*[T: tuple](v: PPyObject, o: var T) =
  let (getSize, getItem) = getListOrTupleAccessors(v)
  const sz = tupleSize[T]()
  if not getSize.isNil and getSize(v) == sz:
    var i = 0
    for f in fields(o):
      let pf = getItem(v, i)
      pyValueToNim(pf, f)
      # No DECREF here. PyTuple_GetItem returns a borrowed ref.
      inc i
  else:
    pyValueToNimRaiseConversionError($type(o))
