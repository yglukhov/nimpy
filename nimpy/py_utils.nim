import strutils, macros

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
  raise newException(ValueError, "Can't convert python obj to string")

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

macro generateRaiseCase(typ: PPyObject, typns, valns: string): untyped =
  ## generate the calls to `PyErr_GivenExceptionMatches` to check which exception
  ## matches for `typ`.
  ## allows us to detect if exception is subclass of another
  ## if pyLib.PyErr_GivenExceptionMatches(typ, pyLib.PyExc_OSError):
  ##   peKind = peOSError
  ## ...
  ## once `peKind` is defined, generates the case statement to map Python
  ## Exceptions to Nim exception
  ## case peKind
  ## of peOSError
  ##   raise newException(OSError, typns & ": " & valns)
  ## .. # and so on
  result = newStmtList()
  let
    # identifiers for pyLib
    pyLib = ident("pyLib")
    pyVersion = ident("pythonVersion")
    givenExcMatch = ident("PyErr_GivenExceptionMatches")
    peKind = ident("peKind")
  # bind `PythonErrorKind` and get its implementation
  let peEnumImpl = bindSym("PythonErrorKind").getImpl

  # add declaration of `peKind` to result
  let peKindVar = quote do:
    var `peKind`: PythonErrorKind

  # stores the if statements that perform the calls to `PyErr_GivenExceptionMatches`
  # to check which exception it is
  var excIfStmts = newStmtList()
  # stores the `of` branches of the `case` statement that is done on the
  # `PythonErrorKind` gathered from the `excIfStmts`
  var ofBranches: seq[NimNode]

  # iterate enum fields
  for x in peEnumImpl[2]:
    if x.kind == nnkEnumFieldDef:
      # enum consists of: `pe<NimExceptionName> = "PythonExceptionName"`
      let peNode = x[0]
      var nimExc = peNode.strVal
      let ofExpr = ident(nimExc)
      # get name and remove "pe" prefix to get Nim Exception
      removePrefix(nimExc, "pe")
      let nimExcIdent = ident(nimExc)
      let raiseStmt = quote do:
        raise newException(`nimExcIdent`, `typns` & ": " & `valns`)
      ofBranches.add nnkOfBranch.newTree(ofExpr, raiseStmt)
      # build name of corresponding Python exception
      let fieldVal = x[1].strVal
      let pyError = ident("PyExc_" & fieldVal)
      excIfStmts.add quote do:
        if `pyLib`.`givenExcMatch`(`typ`, `pyLib`.`pyError`) == 1.cint:
          `peKind` = `peNode`

  # perform check if Python 2 or 3 is run, due to `IOError` == `OSError` in
  # Python 3.
  let peOSError = ident("peOSError")
  let peIOError = ident("peIOError")
  let py3Check = quote do:
    if `pyLib`.`pyVersion` == 3 and `peKind` == `peIOError`:
      # if Py3 and `IOError`, rewrite to `OSError`
      `peKind` = `peOSError`

  var caseStmt = nnkCaseStmt.newTree(
    peKind)
  for o in ofBranches:
    caseStmt.add o

  result.add peKindVar
  result.add excIfStmts
  result.add py3Check
  result.add caseStmt

proc raisePythonError*() =
    var typ, val, tb: PPyObject
    pyLib.PyErr_Fetch(addr typ, addr val, addr tb)
    pyLib.PyErr_NormalizeException(addr typ, addr val, addr tb)

    let vals = pyLib.PyObject_Str(val)
    let typs = pyLib.PyObject_Str(typ)
    var typns, valns: string
    if unlikely(not (pyStringToNim(vals, valns) and pyStringToNim(typs, typns))):
      raise newException(AssertionError, "Can not stringify exception")
    decRef vals
    decRef typs

    # generate the code for the checks to get the correct Python Exception and
    # then generate the case statement to map to the equivalent Nim exception
    generateRaiseCase(typ, typns, valns)
