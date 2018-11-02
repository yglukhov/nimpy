import ../nimpy, ../nimpy/raw_buffers, strutils, os, typetraits, tables, json

proc test*() =
    let py = pyBuiltinsModule()
    let s = py.sum(py.range(0, 5)).to(int)
    doAssert(s == 10)

    block:
        doAssert(pyImport("os").getcwd().to(string) == getCurrentDir())

        discard pyImport("sys").path.append("tests")

        let pfn = pyImport("pyfromnim")
        let o = pfn.MyClass()
        doAssert(o.someFunc(7, 5).to(int) == 2)

        doAssert(pfn.MyClass.staticFunc(7, 5).to(int) == 12)

        var excMsg = ""
        try:
            discard pfn.MyClass.raisingFunc()
        except:
            excMsg = getCurrentExceptionMsg()
        doAssert(excMsg.endsWith("Exception'>: hello"))

    block:
        var ints = newSeq[int]()
        var strs = newSeq[string]()
        for i in py.`range`(0, 5):
            ints.add(i.to(int))
            strs.add($i)
        doAssert(ints == @[0, 1, 2, 3, 4])
        doAssert(strs == @["0", "1", "2", "3", "4"])

    block:
        var lst = py.list(py.`range`(0, 4))
        discard lst.reverse()
        doAssert(lst[0].to(int) == 3)
        doAssert(lst[1].to(int) == 2)
        doAssert(lst[3].to(int) == 0)

        var s = newSeq[int]()
        # Iterate over lst
        for i in lst: s.add(i.to(int))
        doAssert(s == @[3, 2, 1, 0])

        lst[0] = 9
        lst[1] = 8
        lst[2] = 7
        lst[3] = 6

        s = @[]
        for i in lst: s.add(i.to(int))
        doAssert(s == @[9, 8, 7, 6])

    block: # numpy test
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

    block: # kwargs test
        let pfn = pyImport("pyfromnim")
        let x = pfn.test_kwargs(b = 3, a = 1)

        doAssert(x.to(int) == -2)

    block: # dict test
        let pfn = pyImport("pyfromnim")
        let dict = pfn.test_dict()
        let nimDict = dict.to(Table[string, int])

        doAssert nimDict.len == 3
        doAssert nimDict["Hello"] == 0
        doAssert nimDict["World"] == 1
        doAssert nimDict["Yay"] == 5

    block: # serialize char's
        doAssert(py.ord("A").to(char) == 'A')
        doAssert(py.chr('A').to(string) == "A")

    block: # types without a clear string representation print their type name
        let o = pyImport("pyfromnim").MyClass()

        # Check for a class that does not have __repr__
        var excMsg = ""
        var expectedMsg = "Can't convert python obj of type '$1' to string"
        try:
            discard o.to(string)
        except:
            excMsg = getCurrentExceptionMsg()

        doAssert(excMsg == expectedMsg % "MyClass")

        # Check against the None type
        var n = py.None
        try:
            discard n.to(string)
        except:
            excMsg = getCurrentExceptionMsg()

        doAssert(excMsg == expectedMsg % "NoneType")

    block: # JSON conversion test
        let pfn = pyImport("pyfromnim")
        let dict = pfn.test_dict_json()

        let jsonDict = dict.toJson
        doAssert jsonDict["Hello"].getInt == 0
        doAssert jsonDict["World"].getInt == 1
        doAssert jsonDict["Yay"].getFloat == 5.5
        doAssert jsonDict["5"].getInt == 10
        doAssert jsonDict["Complex"] == %* { "real" : -1.0,
                                             "imag" : 2.2 }
        doAssert jsonDict["Nested"] == %* { "Dict" : 12.7 }
        doAssert "pyfromnim.MyClass" in jsonDict["Object"].getStr
        doAssert jsonDict["List"][0].getInt == 1
        doAssert jsonDict["List"][1].getInt == 2
        doAssert jsonDict["List"][2].getInt == 3
        doAssert jsonDict["List"][3].getInt == 4

        doAssert jsonDict["ListFloat"][0].getFloat == 1.5
        doAssert jsonDict["ListFloat"][1].getFloat == 2.2
        doAssert jsonDict["ListFloat"][2].getFloat == 3.5
        doAssert jsonDict["ListFloat"][3].getFloat == 4.0

        doAssert jsonDict["ListMixed"][0].getInt == 1
        doAssert jsonDict["ListMixed"][1].getFloat == 2.2
        doAssert jsonDict["ListMixed"][2].getInt == 3
        doAssert jsonDict["ListMixed"][3].getFloat == 4.0
        doAssert jsonDict["ListMixed"][4] == %* { "real" : -1.5,
                                                  "imag" : 2.2 }

        doAssert jsonDict["Tuple"][0].getFloat == 5.5
        doAssert jsonDict["Tuple"][1].getFloat == 10.0

    block: # test mapping of exceptions
        let pfn = pyImport("traise")
        template check(f: untyped, exc: varargs[untyped]): untyped =
            try:
              discard f()
            except exc:
              discard

        check(pfn.testOSError, OSError)
        # in python3 IOError == OSError
        check(pfn.testIOError, IOError, OSError)
        check(pfn.testValueError, ValueError)
        check(pfn.testKeyError, KeyError)
        check(pfn.testEOFError, EOFError)
        check(pfn.testArithmeticError,ArithmeticError)
        check(pfn.testZeroDivisionError, DivByZeroError)
        check(pfn.testOverflowError, OverflowError)
        check(pfn.testAssertionError, AssertionError)
        check(pfn.testMemoryError, OutOfMemError)
        check(pfn.testIndexError, IndexError)
        check(pfn.testFloatingPointError, FloatingPointError)
        check(pfn.testException, Exception)
        check(pfn.testUnsupportedException, Exception)
        check(pfn.testCustomException, IndexError)

    block: # Function objects
        let pfn = pyImport("pyfromnim")
        var
            aa, bb = 0
            cc = ""
        proc myFn(a, b: int, c: string) =
            aa = a
            bb = b
            cc = c
        discard pfn.call_callback(myFn)
        doAssert(aa == 1)
        doAssert(bb == 2)
        doAssert(cc == "Hello")

when isMainModule:
    test()
    echo "Test complete!"
