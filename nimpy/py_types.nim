
type
    PPyObject* = distinct pointer
    Py_ssize_t* = csize

    PyCFunction* = proc(s, a: PPyObject): PPyObject {.cdecl.}

    PyMethodDef* = object
        ml_name*: cstring
        ml_meth*: PyCFunction
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

    Destructor* = proc(o: PPyObject) {.cdecl.}
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
    Initproc* = proc(a, b, c: PPyObject): cint {.cdecl.}
    Newfunc* = proc(typ: PyTypeObject, a, b: PPyObject): PPyObject {.cdecl.}
    Allocfunc* = proc(typ: PyTypeObject, sz: Py_ssize_t): PPyObject {.cdecl.}
    Freefunc* = proc(p: pointer) {.cdecl.}
    Cmpfunc* = proc(a, b: PPyObject): cint {.cdecl.}

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

proc isNil*(p: PPyObject): bool {.borrow.}

