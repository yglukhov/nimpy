
type
  MPObj {.importc: "mp_obj_t", header: "py/obj.h".} = distinct pointer

var
  mp_const_none {.importc, header: "py/obj.h".}: MPObj

proc c_printf(fmt: cstring) {.nodecl, importc: "printf", header: "stdio.h", varargs.}

proc mymodule_hello(): MPObj {.exportc.} =
  c_printf("Hello nim!\n")
  mp_const_none

{.emit: """
#include "py/nlr.h"
#include "py/obj.h"
#include "py/runtime.h"
#include "py/binary.h"

STATIC MP_DEFINE_CONST_FUN_OBJ_0(mymodule_hello_obj, mymodule_hello);

STATIC const mp_map_elem_t mymodule_globals_table[] = {
    { MP_OBJ_NEW_QSTR(MP_QSTR___name__), MP_OBJ_NEW_QSTR(MP_QSTR_mymodule) },
    { MP_OBJ_NEW_QSTR(MP_QSTR_hello), (mp_obj_t)&mymodule_hello_obj },
};

STATIC MP_DEFINE_CONST_DICT (
    mp_module_mymodule_globals,
    mymodule_globals_table
);

const mp_obj_module_t mp_module_mymodule = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t*)&mp_module_mymodule_globals,
};

""".}
