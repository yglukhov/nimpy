## Use nimpy to access numpy arrays from python

* Get buffer from numpy array (PyObject)
    - Note
        - numpy will export buffer when the underlying memory block is C-Contiguous
        - if the underlying data is not C-Contiguous, there will be a PythonException thrown by numpy
```nim
proc asNimArray*[T](arr : PyObject, mode : int = PyBUF_READ) : ptr UncheckedArray[T] =
    var
        buf : RawPyBuffer
    getBuffer(arr, buf, mode.cint)
```

* Shape and Strides
```nim
type
    NimNumpyArray*[T] = object
        originalPtr*   : PyObject
        buf*           : ptr UncheckedArray[T]
        shape*         : seq[int]
        strides*       : seq[int]
        c_contiguous*  : bool
        f_contiguous*  : bool

proc asNimNumpyArray*[T](arr : PyObject, mode : int = PyBUF_READ) : NimNumpyArray[T] =
    #[
        Function to translate numpy array into an object in Nim to represent the data for convinience.
    ]#
    result.originalPtr        = arr
    result.buf                = asNimArray[T](arr, mode)
    result.shape              = getAttr(arr, "shape").to(seq[int])
    result.strides            = getAttr(arr, "strides").to(seq[int])
    result.c_contiguous       = arr.flags["C_CONTIGUOUS"].to(bool)
    result.f_contiguous       = arr.flags["F_CONTIGUOUS"].to(bool)

proc accessNumpyMatrix*[T](matrix : NimNumpyArray[T], row, col : int): T =
    doAssert matrix.shape == 2 and matrix.strides == 2
    return matrix.buf[
        row * matrix.strides[0] + col * matrix.strides[1]
    ]
```

* ArrayMancer Tensor
-  Given the exposed buffer, you can use cpuStorageFromBuffer from ArrayMancer Tensor wihout making a copy
