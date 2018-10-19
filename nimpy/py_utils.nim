import strscans, strutils, macros

import py_lib as lib
import py_types

proc incRef*(p: PPyObject) {.inline.} =
    inc p.to(PyObjectObj).ob_refcnt

proc decRef*(p: PPyObject) {.inline.} =
    let o = p.to(PyObjectObj)
    dec o.ob_refcnt
    if o.ob_refcnt == 0:
        pyLib.PyDealloc(p)

proc checkObjSubclass*(o: PPyObject, flags: int): bool {.inline.} =
    let typ = cast[PyTypeObject]((cast[ptr PyObjectObj](o)).ob_type)
    (typ.tp_flags and flags.culong) != 0

proc checkObjSubclass*(o: PPyObject, ty: PyTypeObject): bool {.inline.} =
    var typ = cast[PyTypeObject]((cast[ptr PyObjectObj](o)).ob_type)
    (ty == typ) or pyLib.PyType_IsSubtype(typ, ty) != 0

proc conversionToStringError() =
  pyLib.PyErr_Clear()
  raise newException(Exception, "Can't convert python obj to string")

proc pyStringToNim*(o: PPyObject, output: var string): bool =
    var s: ptr char
    var l: Py_ssize_t
    var b: PPyObject

    if checkObjSubclass(o, pyLib.PyUnicode_Type):
        b = pyLib.PyUnicode_AsUTF8String(o)
        if b.isNil:
            conversionToStringError()
        if pyLib.PyBytes_AsStringAndSize(b, addr s, addr l) != 0:
            decRef b
            conversionToStringError()
    elif checkObjSubclass(o, pyLib.PyBytes_Type):
        if pyLib.PyBytes_AsStringAndSize(o, addr s, addr l) != 0:
            conversionToStringError()
    else:
        return

    output = newString(l) # XXX: No init zero-init required here
    if l != 0:
        copyMem(addr output[0], s, l)

    if not b.isNil:
        decRef b

    result = true

proc extractPythonError(typ: string): PythonErrorKind =
  var error = ""
  if scanf(typ, "<class '$*'>", error):
    try:
      result = parseEnum[PythonErrorKind](error)
    except ValueError:
      # exception not supported, return general exception
      result = peException
  else:
    # else return general exception
    result = peException

macro generateRaiseCase(peKind: PythonErrorKind, typns, valns: string): untyped =
  ## generates a case statement to map Python Exceptions to Nim exception
  ## case peKind
  ## of peOSError
  ##   raise newException(OSError, typns & ": " & valns)
  ## .. # and so on
  let peEnumImpl = bindSym("PythonErrorKind").getImpl
  var ofBranches: seq[NimNode]
  # iterate enum fields
  for x in peEnumImpl[2]:
    if x.kind == nnkEnumFieldDef:
      # get name and remove "pe" prefix to get Nim Exception
      let ofExpr = ident(x[0].strVal)
      var nimExc = x[0].strVal
      removePrefix(nimExc, "pe")
      let nimExcIdent = ident(nimExc)
      let raiseStmt = quote do:
        raise newException(`nimExcIdent`, `typns` & ": " & `valns`)
      ofBranches.add nnkOfBranch.newTree(ofExpr, raiseStmt)
  result = nnkCaseStmt.newTree(
    peKind)
  for o in ofBranches:
    result.add o

proc raisePythonError*() =
    var typ, val, tb: PPyObject
    pyLib.PyErr_Fetch(addr typ, addr val, addr tb)
    pyLib.PyErr_NormalizeException(addr typ, addr val, addr tb)
    let vals = pyLib.PyObject_Str(val)
    let typs = pyLib.PyObject_Str(typ)
    var typns, valns: string
    if unlikely(not (pyStringToNim(vals, valns) and pyStringToNim(typs, typns))):
      raise newException(Exception, "Can not stringify exception")
    decRef vals
    decRef typs
    # extract the correct `PythonErrorKind` from the exception's name
    let peKind = extractPythonError(typns)
    # and generate the case branches for all exceptions based on it
    generateRaiseCase(peKind, typns, valns)
