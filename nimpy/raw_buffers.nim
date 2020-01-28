import py_types, py_utils
import py_lib as lib
from ../nimpy import PyObject, privateRawPyObj

export RawPyBuffer

const
  # Flags for getting buffers
  PyBUF_SIMPLE*         = 0
  PyBUF_WRITABLE*       = 0x0001

  PyBUF_FORMAT*         = 0x0004
  PyBUF_ND*             = 0x0008
  PyBUF_STRIDES*        = 0x0010 or PyBUF_ND
  PyBUF_C_CONTIGUOUS*   = 0x0020 or PyBUF_STRIDES
  PyBUF_F_CONTIGUOUS*   = 0x0040 or PyBUF_STRIDES
  PyBUF_ANY_CONTIGUOUS* = 0x0080 or PyBUF_STRIDES
  PyBUF_INDIRECT*       = 0x0100 or PyBUF_STRIDES

  PyBUF_CONTIG*         = PyBUF_ND or PyBUF_WRITABLE
  PyBUF_CONTIG_RO*      = PyBUF_ND

  PyBUF_STRIDED*        = PyBUF_STRIDES or PyBUF_WRITABLE
  PyBUF_STRIDED_RO*     = PyBUF_STRIDES

  PyBUF_RECORDS*        = PyBUF_STRIDES or PyBUF_WRITABLE or PyBUF_FORMAT
  PyBUF_RECORDS_RO*     = PyBUF_STRIDES or PyBUF_FORMAT

  PyBUF_FULL*           = PyBUF_INDIRECT or PyBUF_WRITABLE or PyBUF_FORMAT
  PyBUF_FULL_RO*        = PyBUF_INDIRECT or PyBUF_FORMAT

  PyBUF_READ*           = 0x100
  PyBUF_WRITE*          = 0x200
  PyBUF_SHADOW*         = 0x400

proc getBuffer*(o: PyObject, buf: var RawPyBuffer, flags: cint) =
  let gb = pyLib.PyObject_GetBuffer
  if likely(not gb.isNil):
    if unlikely gb(o.privateRawPyObj, buf, flags) != 0:
      raisePythonError()
  else:
    raise newException(Exception, "nimpy: Buffer API is not available")

proc release*(buf: var RawPyBuffer) =
  let rb = pyLib.PyBuffer_Release
  if likely(not rb.isNil):
    rb(buf)
