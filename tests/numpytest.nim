import nimpy, nimpy/raw_buffers

proc test() {.exportpy.} =
  let numpy = pyImport("numpy")
  let a = numpy.arange(4)

  var s = newSeq[string]()
  for i in a:
    s.add($i)

  doAssert(s == @["0", "1", "2", "3"])

  var aBuf: RawPyBuffer
  a.getBuffer(aBuf, PyBUF_WRITABLE or PyBUF_ND)
  doAssert(aBuf.ndim == 1)
  cast[ptr cint](aBuf.buf)[] = 123
  aBuf.release()
  doAssert(a[0].to(int) == 123)

  let ndArray = numpy.`array`(@[@[1, 2, 3], @[4, 5, 6], @[7, 8, 9]])
  var ndBuf: RawPyBuffer
  ndArray.getBuffer(ndBuf, PyBUF_WRITABLE or PyBUF_ND)
  doAssert(ndBuf.ndim == 2)
  ndBuf.release()
