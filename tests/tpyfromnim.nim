import ../nimpy, strutils, os

let py = pyBuiltinsModule()
let s = py.sum(py.range(0, 5)).to(int)
doAssert(s == 10)

block:
    doAssert(pyImport("os").getcwd().to(string) == getCurrentDir())

    discard pyImport("sys").path.append("tests")

    let pfn = pyImport("pyfromnim")
    doAssert(not pfn.isNil)
    let o = pfn.MyClass()
    doAssert(o.someFunc(7, 5).to(int) == 2)

    doAssert(pfn.MyClass.staticFunc(7, 5).to(int) == 12)

    var excMsg = ""
    try:
        discard pfn.MyClass.raisingFunc()
    except:
        excMsg = getCurrentExceptionMsg()
    doAssert(excMsg.endsWith("Exception'>: hello"))

echo "Test complete!"
