import std/[json, complex, tables]
import ./py_types, ./py_utils
import ./py_lib as lib

# Enum handling
proc nimpyEnumConvert*[T](o: T): int=
  ## Enum handling
  ## Default is ordinal integer
  ## User is can freely overload any proc named `nimEnumConvert` that returns a string or an int
  ## It will effectively overload how the conversion of the enum is done
  ord(o)

proc newPyNone*(): PPyObject {.inline.} =
  incRef(pyLib.Py_None)
  pyLib.Py_None

proc nimValueToPy*(_: typeof(nil)): PPyObject {.inline.} = newPyNone()
proc nimValueToPy*(v: PPyObject): PPyObject {.inline.} = v

proc nimValueToPy*(v: cstring): PPyObject {.inline.} = pyLib.Py_BuildValue("s", v)
proc nimValueToPy*(s: string): PPyObject =
  var cs: cstring = s
  var ln = s.len.cint
  result = pyLib.Py_BuildValue("s#", cs, ln)
  if result.isNil:
    # Utf-8 decoding failed. Fallback to bytes.
    pyLib.PyErr_Clear()
    result = pyLib.Py_BuildValue("y#", cs, ln)

  assert(not result.isNil, "nimpy internal error converting string")

proc nimValueToPy*(v: int8): PPyObject {.inline.} = pyLib.Py_BuildValue("b", v)
proc nimValueToPy*(v: int16): PPyObject {.inline.} = pyLib.Py_BuildValue("h", v)
proc nimValueToPy*(v: int32): PPyObject {.inline.} = pyLib.Py_BuildValue("i", v)
proc nimValueToPy*(v: int64): PPyObject {.inline.} = pyLib.Py_BuildValue("L", v)

proc nimValueToPy*(v: uint8|char): PPyObject {.inline.} = pyLib.Py_BuildValue("B", v)
proc nimValueToPy*(v: uint16): PPyObject {.inline.} = pyLib.Py_BuildValue("H", v)
proc nimValueToPy*(v: uint32): PPyObject {.inline.} = pyLib.Py_BuildValue("I", v)
proc nimValueToPy*(v: uint64): PPyObject {.inline.} = pyLib.Py_BuildValue("K", v)

proc nimValueToPy*(v: int): PPyObject {.inline.} =
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

proc nimValueToPy*(v: uint): PPyObject {.inline.} =
  when sizeof(uint) == sizeof(uint64):
    nimValueToPy(uint64(v))
  elif sizeof(uint) == sizeof(uint32):
    nimValueToPy(uint32(v))
  elif sizeof(uint) == sizeof(uint16):
    nimValueToPy(uint16(v))
  elif sizeof(uint) == sizeof(uint8):
    nimValueToPy(uint8(v))
  else:
    {.error: "Unkown uint size".}

proc nimValueToPy*(v: float | float32 | float64): PPyObject {.inline.} = pyLib.Py_BuildValue("d", float64(v))
proc nimValueToPy*(v: bool): PPyObject {.inline.} = pyLib.PyBool_FromLong(clong(v))

proc nimValueToPy*(v: enum): PPyObject {.inline.} =
  mixin nimpyEnumConvert
  nimValueToPy(nimpyEnumConvert(v))

proc nimValueToPy*(node: JsonNode): PPyObject =
  case node.kind
  of JNull:
    result = newPyNone()
  of JInt:
    result = nimValueToPy(node.getInt)
  of JFloat:
    result = nimValueToPy(node.getFloat)
  of JBool:
    result = nimValueToPy(node.getBool)
  of JString:
    result = nimValueToPy(node.getStr)
  of JArray:
    result = pyLib.PyList_New(node.len)
    for i in 0 ..< node.len:
      let o = nimValueToPy(node[i])
      discard pyLib.PyList_SetItem(result, i, o)
      # No decRef here. PyList_SetItem "steals" the reference to `o`
  of JObject:
    result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
    for k, v in node:
      let vv = nimValueToPy(v)
      let ret = pyLib.PyDict_SetItemString(result, cstring(k), vv)
      decRef vv
      if ret != 0:
        cannotSerializeErr(k)

proc nimValueToPy*(v: Complex): PPyObject {.inline.} =
  when declared(Complex64):
    when v is Complex64:
      pyLib.Py_BuildValue("D", unsafeAddr v)
    else:
      let vv = complex64(v.re, v.im)
      pyLib.Py_BuildValue("D", unsafeAddr vv)
  else:
    pyLib.Py_BuildValue("D", unsafeAddr v)

proc nimValueToPy*[T](v: openArray[T]): PPyObject =
  when T is byte:
    result = pyLib.PyBytesFromStringAndSize(cast[ptr char](v), v.len)
  else:
    let sz = v.len
    result = pyLib.PyList_New(sz)
    for i in 0 ..< sz:
      let o = nimValueToPy(v[i])
      discard pyLib.PyList_SetItem(result, i, o)
      # No decRef here. PyList_SetItem "steals" the reference to `o`

proc nimValueToPy*(t: Table): PPyObject =
  result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
  for k, v in t:
    let vv = nimValueToPy(v)
    when type(k) is string:
      let ret = pyLib.PyDict_SetItemString(result, cstring(k), vv)
    else:
      let kk = nimValueToPy(k)
      let ret = pyLib.PyDict_SetItem(result, kk, vv)
      decRef kk
    decRef vv
    if ret != 0:
      cannotSerializeErr($k)

proc nimValueToPyDict*(o: object | tuple): PPyObject =
  result = PyObject_CallObject(cast[PPyObject](pyLib.PyDict_Type))
  for k, v in fieldPairs(o):
    let vv = nimValueToPy(v)
    let ret = pyLib.PyDict_SetItemString(result, k, vv)
    decRef vv
    if ret != 0:
      cannotSerializeErr(k)

proc nimValueToPy*(t: object): PPyObject {.inline.} =
  nimValueToPyDict(t)

proc nimValueToPy*[T: tuple](o: T): PPyObject =
  const sz = tupleSize[T]()
  result = pyLib.PyTuple_New(sz)
  var i = 0
  for f in fields(o):
    discard pyLib.PyTuple_SetItem(result, i, nimValueToPy(f))
    inc i

proc nimValueToPy*(e: ref Exception): PPyObject =
  if e of AssertionDefect:
    pyLib.PyExc_AssertionError
  elif e of EOFError:
    pyLib.PyExc_EOFError
  elif e of FieldDefect:  # Right mapping?
    pyLib.PyExc_AttributeError
  elif e of IndexDefect:
    pyLib.PyExc_IndexError
  elif e of IOError:
    pyLib.PyExc_IOError
  elif e of KeyError:
    pyLib.PyExc_KeyError
  elif e of DivByZeroDefect or e of FloatDivByZeroDefect:
    pyLib.PyExc_ZeroDivisionError
  elif e of FloatingPointDefect:
    pyLib.PyExc_FloatingPointError
  else:
    pyLib.PyErr_NewException(cstring("nimpy" & "." & $(e.name)), pyLib.NimPyException, nil)