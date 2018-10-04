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
    raise newException(Exception, typns & ": " & valns)

