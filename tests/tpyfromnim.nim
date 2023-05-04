import nimpy, strutils, os, typetraits, tables, json

type
  Enum1* = enum
    A1, B1, C1, D1

  Enum2* = enum
    A2 = "A2_String_Enum_Value"
    B2 = "B2_String_Enum_Value"
    C2 = "C2_String_Enum_Value"

  Enum3* = enum
    A3 = "A3_String_Enum_Value"
    B3 = "B3_String_Enum_Value"
    C3 = "C3_String_Enum_Value"

type
  MyObj* = object
    e1*: Enum1
    e2*: Enum2
    e3*: Enum3

proc nimpyEnumConvert*(e: Enum2|Enum3): string =
  $e

proc test*() {.gcsafe.} =
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

  block: # eval
    let py = pyBuiltinsModule()
    doAssert(py.eval("3+3", pyDict(), pyDict()).to(int) == 6)
    doAssert(py.eval(""" "hello" * 2 """, pyDict(), pyDict()).to(string) == "hellohello")

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
    lst.reverse().to(void) # `x.to(void)` is the same as `discard x`
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

  block: # attr setters and getters
    let o = pyImport("pyfromnim").MyClass()
    o.my_field_in_nim = 5
    doAssert(o.my_field_in_nim.to(int) == 5)

  block: # JSON conversion test
    let pfn = pyImport("pyfromnim")
    let dict = pfn.test_dict_json()

    let jsonDict = dict.to(JsonNode)
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
      var ok = false
      try:
        discard f()
      except exc:
        ok = true
      assert(ok)

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

  block: # Comparison
    let py = pyBuiltinsModule()
    doAssert(py.None == py.None)

  block: # cstring args
    let pfn = pyImport("pyfromnim")
    let res = pfn.concat_strings(cstring("Hello"), " world").to(string)
    doAssert(res == "Hello world")

  block: # Enums
    let pfn = pyImport("pyfromnim")

    var obj1 = MyObj(e1: A1, e2: A2, e3: A3)

    doAssert(pfn.test_enum1(obj1).to(int) == ord(obj1.e1))
    doAssert(pfn.test_enum2(obj1).to(string) == $(obj1.e2))
    doAssert(pfn.test_enum3(obj1).to(string) == $(obj1.e3))

    doAssert(pfn.test_enum1(obj1).to(Enum1) == A1)
    doAssert(pfn.test_enum2(obj1).to(Enum2) == A2)

    var obj2 = MyObj(e1: B1, e2: B2, e3: B3)
    doAssert(pfn.test_enum1(obj2).to(int) == ord(obj2.e1))
    doAssert(pfn.test_enum2(obj2).to(string) == $(obj2.e2))
    doAssert(pfn.test_enum3(obj2).to(string) == $(obj2.e3))

  block: # Nested marshalling
    let pfn = pyImport("pyfromnim")
    type Foo = object
      a: seq[int]
      b: (seq[int], string)
    doAssert(pfn.test_nested_marshalling(Foo(a: @[0, 1, 123], b: (@[0, 123, 2], "hello"))).to(bool))

  block: # Nil marshalling
    let pfn = pyImport("pyfromnim")
    doAssert(pfn.test_nil_marshalling(nil).to(bool))
    var myNil: PyObject
    doAssert(pfn.test_nil_marshalling(myNil).to(bool))
    myNil = nil
    doAssert(pfn.test_nil_marshalling(myNil).to(bool))

  block: # Kinda subclassing python objects in nim and calling super
    if pyImport("sys").version_info.major.to(int) >= 3: # Only test with python 3
      let py = pyBuiltinsModule()
      let locals = toPyDict(()) # Create empty dict

      # Let's say there's this python code:
      discard py.exec("""
      class Foo:
        def overrideMe(self):
          return 2

      def useFoo(foo):
        return foo.overrideMe()
      """.dedent(), pyDict(), locals)

      let fooClass = locals["Foo"]

      # Create a subclass of Foo in Nim:
      proc createFooSubclassInstance(): PyObject =
        # The subclass is created with python `type` function
        # Currently we don't have means to get `self` argument inside a method,
        # so we keep `self` around in the closure environment

        var self: PyObject

        proc overrideMe(): int =
          self.super.overrideMe().to(int) + 123 # Call super

        self = py.`type`("_", (fooClass, ), toPyDict({
          "overrideMe": overrideMe
        })).to(proc(): PyObject {.gcsafe.})()
        return self

      # Create an instance of Bar
      let b = createFooSubclassInstance()

      # Get `useFoo` proc
      let useFoo = locals["useFoo"].to(proc(self: PyObject): int {.gcsafe.})

      # Pass b to `useFoo`
      doAssert(useFoo(b) == 125)

when isMainModule:
  test()
  echo "Test complete!"
