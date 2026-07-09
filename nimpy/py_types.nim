
when (NimMajor, NimMinor) < (1, 2):
  type csize_t = csize

type
  PPyObject* = ptr object
  Py_ssize_t* = int

  PyCFunction* = proc(s, a: PPyObject): PPyObject {.cdecl.}

  PyCFunctionWithKeywords* = proc(s, a, k: PPyObject): PPyObject {.cdecl.}

  PyMethodDef* = object
    ml_name*: cstring
    ml_meth*: PyCFunctionWithKeywords
    ml_flags*: cint
    ml_doc*: cstring

  PyMemberDef* = object
    name*: cstring
    typ*: cint
    offset*: Py_ssize_t
    flags*: cint
    doc*: cstring

  PyModuleDef_Slot* = object
    slot*: cint
    value*: pointer

  PyObject_HEAD_EXTRA* = object
    ob_next*: pointer
    ob_prev*: pointer

  PyObjectObj* {.pure, inheritable.} = object
    # extra: PyObject_HEAD_EXTRA # in runtime depends on traceRefs. see pyAlloc
    ob_refcnt*: Py_ssize_t
    ob_type*: pointer

  PyObjectVarHeadObj* = object of PyObjectObj
    ob_size*: Py_ssize_t

  PyModuleDef_Base* = object
    ob_base*: PyObjectObj
    m_init*: proc(): PPyObject {.cdecl.}
    m_index*: Py_ssize_t
    m_copy*: PPyObject

  PyModuleDef* = object
    m_base*: PyModuleDef_Base
    m_name*: cstring
    m_doc*: cstring
    m_size*: Py_ssize_t
    m_methods*: ptr PyMethodDef
    m_slots*: ptr PyModuleDef_Slot
    m_traverse*: pointer

    m_clear*: pointer
    m_free*: pointer

  Destructor* = proc(o: PPyObject) {.cdecl, gcsafe.}
  Printfunc* = proc(o: PPyObject, f: File, c: cint): cint {.cdecl}
  Getattrfunc* = proc(o: PPyObject, a: cstring): PPyObject {.cdecl.}
  Getattrofunc* = proc(o, a: PPyObject): PPyObject {.cdecl.}
  Setattrfunc* = proc(o: PPyObject, a: cstring, at: PPyObject): cint {.cdecl.}
  Setattrofunc* = proc(o, a, at: PPyObject): cint {.cdecl.}
  Reprfunc* = proc(o: PPyObject): PPyObject {.cdecl.}
  Richcmpfunc* = proc(a, b: PPyObject, c: cint): PPyObject {.cdecl.}
  Getiterfunc* = proc(a: PPyObject): PPyObject {.cdecl.}
  Iternextfunc* = proc(a: PPyObject): PPyObject {.cdecl.}
  Descrgetfunc* = proc(a, b, c: PPyObject): PPyObject {.cdecl.}
  Descrsetfunc* = proc(a, b, c: PPyObject): cint {.cdecl.}
  Initproc* = proc(a, b, c: PPyObject): cint {.cdecl, gcsafe.}
  Newfunc* = proc(typ: PyTypeObject, a, b: PPyObject): PPyObject {.cdecl.}
  Allocfunc* = proc(typ: PyTypeObject, sz: Py_ssize_t): PPyObject {.cdecl.}
  Freefunc* = proc(p: pointer) {.cdecl.}
  Cmpfunc* = proc(a, b: PPyObject): cint {.cdecl.}
  Vectorcallfunc* = proc(c: PPyObject, args: ptr PPyObject, nargs: csize_t, kwnames: PPyObject): PPyObject {.cdecl.}

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

  PyTypeObject3* = ptr PyTypeObject3Obj
  PyTypeObject3Obj* = object of PyObjectVarHeadObj
    tp_name*: cstring
    tp_basicsize*, tp_itemsize*: Py_ssize_t

    # Methods to implement standard operations
    tp_dealloc*: Destructor
    tp_print*: Printfunc

    tp_getattr*: Getattrfunc
    tp_setattr*: Setattrfunc

    tp_as_async*: pointer

    tp_repr*: Reprfunc

    # Method suites for standard classes

    tp_as_number*: pointer
    tp_as_sequence*: pointer
    tp_as_mapping*: pointer


    # More standard operations (here for binary compatibility)

    tp_hash*: pointer # hashfunc
    tp_call*: pointer # ternaryfunc
    tp_str*: Reprfunc
    tp_getattro*: Getattrofunc
    tp_setattro*: Setattrofunc

    # Functions to access object as input/output buffer
    tp_as_buffer*: pointer

    # Flags to define presence of optional/expanded features
    tp_flags*: culong

    tp_doc*: cstring

    # call function for all accessible objects
    tp_traverse*: pointer

    # delete references to contained objects
    tp_clear*: pointer # inquiry

    # rich comparisons
    tp_richcompare*: Richcmpfunc

    # weak reference enabler
    tp_weaklistoffset*: Py_ssize_t

    # Iterators
    tp_iter*: Getiterfunc
    tp_iternext*: Iternextfunc

    # Attribute descriptor and subclassing stuff
    tp_methods*: ptr PyMethodDef
    tp_members*:  ptr PyMemberDef
    tp_getset*: pointer # ptr PyGetSetDef

    tp_base*: PyTypeObject3
    tp_dict*: PPyObject

    tp_descr_get*: Descrgetfunc
    tp_descr_set*: Descrsetfunc
    tp_dictoffset*: Py_ssize_t

    tp_init*: Initproc
    tp_alloc*: Allocfunc
    tp_new*: Newfunc

    tp_free*: Freefunc
    tp_is_gc*: pointer # inquiry /* For PyObject_IS_GC */

    tp_bases*: ptr PyObjectObj
    tp_mro*: PPyObject # method resolution order. array?
    tp_cache*: PPyObject # array?
    tp_subclasses*: ptr PyObjectObj
    tp_weaklist*: ptr PyObjectObj

    tp_del*: Destructor

    # Type attribute cache version tag. Added in version 2.6 */
    tp_version_tag*: cuint
    tp_finalize*: Destructor
    tp_vectorcall*: Vectorcallfunc

  PyTypeObject2* = ptr PyTypeObject2Obj
  PyTypeObject2Obj* = object of PyObjectVarHeadObj
    tp_name*: cstring
    tp_basicsize*, tp_itemsize*: cint

    # Methods to implement standard operations
    tp_dealloc*: Destructor
    tp_print*: Printfunc

    tp_getattr*: Getattrfunc
    tp_setattr*: Setattrfunc
    tp_compare*: Cmpfunc
    tp_repr*: Reprfunc

    # Method suites for standard classes

    tp_as_number*: pointer
    tp_as_sequence*: pointer
    tp_as_mapping*: pointer


    # More standard operations (here for binary compatibility)

    tp_hash*: pointer # hashfunc
    tp_call*: pointer # ternaryfunc
    tp_str*: Reprfunc
    tp_getattro*: Getattrofunc
    tp_setattro*: Setattrofunc

    # Functions to access object as input/output buffer
    tp_as_buffer*: pointer

    # Flags to define presence of optional/expanded features
    tp_flags*: culong

    tp_doc*: cstring

    # call function for all accessible objects
    tp_traverse*: pointer

    # delete references to contained objects
    tp_clear*: pointer # inquiry

    # rich comparisons
    tp_richcompare*: Richcmpfunc

    # weak reference enabler
    tp_weaklistoffset*: clong

    # Iterators
    tp_iter*: Getiterfunc
    tp_iternext*: Iternextfunc

    # Attribute descriptor and subclassing stuff
    tp_methods*: ptr PyMethodDef
    tp_members*: ptr PyMemberDef
    tp_getset*: pointer # ptr PyGetSetDef

    tp_base*: PyTypeObject2
    tp_dict*: PPyObject

    tp_descr_get*: Descrgetfunc
    tp_descr_set*: Descrsetfunc
    tp_dictoffset*: clong

    tp_init*: Initproc
    tp_alloc*: Allocfunc
    tp_new*: Newfunc

    tp_free*: Freefunc
    tp_is_gc*: pointer # inquiry /* For PyObject_IS_GC */

    tp_bases*: ptr PyObjectObj
    tp_mro*: PPyObject # method resolution order. array?
    tp_cache*: PPyObject # array?
    tp_subclasses*: ptr PyObjectObj
    tp_weaklist*: ptr PyObjectObj

  PyTypeObject* = PyTypeObject3

  PyThreadState2* = object
    next*: ptr PyThreadState2
    interp*: pointer
    frame*: pointer
    # XXX: There's a lot more.

  PyThreadState3* = object
    prev*: ptr PyThreadState3
    next*: ptr PyThreadState3
    interp*: pointer
    frame*: pointer
    # XXX: There's a lot more.

  RawPyBuffer* = object # Same as Py_buffer in Python C API
    buf*: pointer
    obj*: PPyObject
    len*: Py_ssize_t
    itemsize*: Py_ssize_t
    readonly*: cint
    ndim*: cint
    format*: cstring
    shape*: ptr Py_ssize_t
    strides*: ptr Py_ssize_t
    suboffsets*: ptr Py_ssize_t
    smalltable*: array[2, Py_ssize_t] # Don't refer! not available in python 3
    internal*: pointer # Don't ever refer

  # enum to map Python Exceptions to Nim Exceptions.
  # the string value corresponds to the Python Exception
  # while the enum identifier corresponds to the Nim exception (excl. "pe")
  PythonErrorKind* = enum
    peCatchableError = "Exception" # general exception, if no equivalent Nim Exception
    peArithmeticDefect = "ArithmeticError"
    peFloatingPointDefect = "FloatingPointError"
    peOverflowDefect = "OverflowError"
    peDivByZeroDefect = "ZeroDivisionError"
    peAssertionDefect = "AssertionError"
    peOSError = "OSError"
    peIOError = "IOError"
    peValueError = "ValueError"
    peEOFError = "EOFError"
    peOutOfMemDefect = "MemoryError"
    peKeyError = "KeyError"
    peIndexDefect = "IndexError"

const
  #  PyBufferProcs contains bf_getcharbuffer
  Py_TPFLAGS_HAVE_GETCHARBUFFER* = (1 shl 0)

  #  PySequenceMethods contains sq_contains
  Py_TPFLAGS_HAVE_SEQUENCE_IN* = (1 shl 1)

# This is here for backwards compatibility.  Extensions that use the old GC
# API will still compile but the objects will not be tracked by the GC.
#  Py_TPFLAGS_GC 0 #  used to be (1 shl 2) =

  #  PySequenceMethods and PyNumberMethods contain in-place operators
  Py_TPFLAGS_HAVE_INPLACEOPS* = (1 shl 3)

  #  PyNumberMethods do their own coercion
  Py_TPFLAGS_CHECKTYPES* = (1 shl 4)

  #  tp_richcompare is defined
  Py_TPFLAGS_HAVE_RICHCOMPARE* = (1 shl 5)

  #  Objects which are weakly referencable if their tp_weaklistoffset is >0
  Py_TPFLAGS_HAVE_WEAKREFS* = (1 shl 6)

  #  tp_iter is defined
  Py_TPFLAGS_HAVE_ITER* = (1 shl 7)

  #  New members introduced by Python 2.2 exist
  Py_TPFLAGS_HAVE_CLASS* = (1 shl 8)

  #  Set if the type object is dynamically allocated
  Py_TPFLAGS_HEAPTYPE* = (1 shl 9)

  #  Set if the type allows subclassing
  Py_TPFLAGS_BASETYPE* = (1 shl 10)

  #  Set if the type is 'ready' -- fully initialized
  Py_TPFLAGS_READY* = (1 shl 12)

  #  Set while the type is being 'readied', to prevent recursive ready calls
  Py_TPFLAGS_READYING* = (1 shl 13)

  #  Objects support garbage collection (see objimp.h)
  Py_TPFLAGS_HAVE_GC* = (1 shl 14)

  #  These two bits are preserved for Stackless Python, next after this is 17

  Py_TPFLAGS_HAVE_STACKLESS_EXTENSION* = 0

  #  Objects support nb_index in PyNumberMethods
  Py_TPFLAGS_HAVE_INDEX* = (1 shl 17)

  #  Objects support type attribute cache
  Py_TPFLAGS_HAVE_VERSION_TAG* = (1 shl 18)
  Py_TPFLAGS_VALID_VERSION_TAG* = (1 shl 19)

  #  Type is abstract and cannot be instantiated
  Py_TPFLAGS_IS_ABSTRACT* = (1 shl 20)

  #  Has the new buffer protocol
  Py_TPFLAGS_HAVE_NEWBUFFER* = (1 shl 21)

  #  These flags are used to determine if a type is a subclass.
  Py_TPFLAGS_INT_SUBCLASS* = (1 shl 23)
  Py_TPFLAGS_LONG_SUBCLASS* = (1 shl 24)
  Py_TPFLAGS_LIST_SUBCLASS* = (1 shl 25)
  Py_TPFLAGS_TUPLE_SUBCLASS* = (1 shl 26)
  Py_TPFLAGS_STRING_SUBCLASS* = (1 shl 27)
  Py_TPFLAGS_UNICODE_SUBCLASS* = (1 shl 28)
  Py_TPFLAGS_DICT_SUBCLASS* = (1 shl 29)
  Py_TPFLAGS_BASE_EXC_SUBCLASS* = (1 shl 30)
  Py_TPFLAGS_TYPE_SUBCLASS* = (1 shl 31)

  Py_TPFLAGS_DEFAULT_EXTERNAL* = Py_TPFLAGS_HAVE_GETCHARBUFFER or
                                Py_TPFLAGS_HAVE_SEQUENCE_IN or
                                Py_TPFLAGS_HAVE_INPLACEOPS or
                                Py_TPFLAGS_HAVE_RICHCOMPARE or
                                Py_TPFLAGS_HAVE_WEAKREFS or
                                Py_TPFLAGS_HAVE_ITER or
                                Py_TPFLAGS_HAVE_CLASS or
                                Py_TPFLAGS_HAVE_STACKLESS_EXTENSION or
                                Py_TPFLAGS_HAVE_INDEX

  Py_TPFLAGS_DEFAULT_CORE* = Py_TPFLAGS_DEFAULT_EXTERNAL or Py_TPFLAGS_HAVE_VERSION_TAG

  # These flags are used for PyMethodDef.ml_flags
  Py_MLFLAGS_VARARGS* = (1 shl 0)
  Py_MLFLAGS_KEYWORDS* = (1 shl 1)
  Py_MLFLAGS_NOARGS* = (1 shl 2)
  Py_MLFLAGS_O* = (1 shl 3)
  Py_MLFLAGS_CLASS* = (1 shl 4)
  Py_MLFLAGS_STATIC* = (1 shl 5)

  # Rich comparison opcodes
  Py_LT* = 0
  Py_LE* = 1
  Py_EQ* = 2
  Py_NE* = 3
  Py_GT* = 4
  Py_GE* = 5
