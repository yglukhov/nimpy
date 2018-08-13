import ../nimpy, strutils, os

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

    block: # kwargs test
        let pfn = pyImport("pyfromnim")
        let x = pfn.test_kwargs(b = 3, a = 1)

        doAssert(x.to(int) == -2)

    block: # serialize char's
        doAssert(py.ord("A").to(char) == 'A')
        doAssert(py.chr('A').to(string) == "A")

    block: # conversion errors
        doAssertRaises(ValueError):
            discard py.chr('A').to(int)
        doAssertRaises(ValueError):
            discard py.chr('A').to(seq[int])
        doAssertRaises(ValueError):
            discard py.chr('A').to(array[1, int])
        echo py.chr('A').to((int,int))

when isMainModule:
    test()
    echo "Test complete!"
