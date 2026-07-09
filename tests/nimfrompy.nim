import nimpy
import algorithm, complex, dynlib, tables, json
from tpyfromnim import nil

import modules/other_module


type
  JackError* = object of CatchableError


proc greet(name: string, greeting: string="Hello", suffix: string="!"): string {.exportpy.} =
  return greeting & ", " & name & suffix

proc greetEveryoneExceptJack(name: string): string {.exportpy.} =
  if name == "Jack":
    raise newException(JackError, "Cannot greet Jack")
  else:
    return "Hello, " & name & "!"

proc somethingThatReturnsEmptyString(): string {.exportpy.} =
  discard

func sumInts(a, b: int32): int {.exportpy.} = a + b
proc sumFloats(a, b: float): float {.exportpy.} = a + b
proc sumAssorted(a, b: int32, c: uint8, d: int64, e: float32, f: float64, g: float): float {.exportpy.} =
  a.float + b.float + c.float + d.float + e + f + g
proc sumIntsInArray(a: openarray[int]): int {.exportpy.} =
  for i in a: result += i

proc subtractUints(a, b: uint64): uint64 {.exportpy.} = a - b

proc reverseArray(a: seq[int]): seq[int] {.exportpy.} = a.reversed()
proc reverseVec3(a: array[3, float]): array[3, float] {.exportpy.} = [a[2], a[1], a[0]]
proc flipBool(b: bool): bool {.exportpy.} = not b

proc reverseByteArray(a: seq[byte]): seq[byte] {.exportpy.} = a.reversed()
proc reverseByteVec3(a: array[3, byte]): array[3, byte] {.exportpy.} = [a[2], a[1], a[0]]

when declared(Complex64):
  proc complexSqrt(x: Complex64): Complex64 {.exportpy.} = sqrt(x)
  proc complexSeqSqrt(a: seq[Complex64]): seq[Complex64] {.exportpy.} =
    result = newSeq[Complex64](a.len)
    for i, aa in a: result[i] = sqrt(aa)
else:
  proc complexSqrt(x: Complex): Complex {.exportpy.} = sqrt(x)
  proc complexSeqSqrt(a: seq[Complex]): seq[Complex] {.exportpy.} =
    result = newSeq[Complex](a.len)
    for i, aa in a: result[i] = sqrt(aa)


proc sumIntsWithCustomName(a, b: int32): int {.exportpy: "sum_ints".} = a + b

proc getTable(): Table[string, int] {.exportpy.} =
  result = { "Hello" : 0,
       "SomeKey": 10 }.toTable

proc getIntTable(): Table[int, float] {.exportpy.} =
  result = { 0 : 1.0,
       1 : 15.0,
       10 : 5.0 }.toTable

proc getJsonAsDict(): JsonNode {.exportpy.} =
  result = %* { "SomeKey" : 1.0,
                "Another" : 5,
                "Foo" : [1, 2, 3.5, {"InArray" : 5}],
                "Bar" : { "Nested" : "Value" }
              }

type
  MyObj = object
    a, b: int
    c: string

  MyRefObj = ref MyObj

proc getMyObj(): MyObj {.exportpy.} =
  result.a = 5
  result.c = "hello"

proc validateMyObj(o: MyObj): bool {.exportpy.} =
  o.a == 5 and o.c == "hello"

proc getMyRefObj(): MyRefObj {.exportpy.} =
  result.new
  result.c = "123"
  result.a = cast[int](result)

proc validateMyRefObj(o: MyRefObj): bool {.exportpy.} =
  o.a == cast[int](o) and o.c == "123"

proc getNilObj(): MyRefObj {.exportpy.} = discard
proc validateNilObj(o: MyRefObj): bool {.exportpy.} = o.isNil

proc voidProc() {.exportpy.} =
  discard

proc someFunc1(o: PyObject): PyObject {.exportpy.} = o.sum(o.range(1, 5))
proc someFunc2(o: PyObject): int {.exportpy.} =
  o.callMethod(int, "sum", o.callMethod("range", 1, 5))

proc someFunc3(): string {.exportpy.} =
  doAssert(someFunc2(pyBuiltinsModule()) == 10)
  result = pyImport("os").getcwd().to(string)

proc tupleDiff(a, b: tuple[x, y: int]): tuple[x, y: int] {.exportpy.} =
  result = (a.x - b.x, a.y - b.y)

proc testPyFromNim() {.exportpy.} =
  tpyfromnim.test()

proc testDefaultArgs(a: string, b: string = "world"): string {.exportpy.} =
  result = a & b

proc testJsonArgument(n: JsonNode): string {.exportpy.} =
  assert(n["foo"].getInt() == 666)
  assert(n["bar"].getBool() == false)
  assert(n["baz"].getFloat() > 41 and n["baz"].getFloat() < 43)
  return "ok"

proc testLambda(p: PyObject): int {.exportpy.} =
  p.callObject(3).to(int)

proc testLambda2(p: proc(a: int): int): int {.exportpy.} =
  p(3)

proc testVoidLambda(p: proc(a: string)) {.exportpy.} =
  p("hello")

proc testNilLambda(p: proc(a: string)): bool {.exportpy.} =
  p.isNil

# Issue #95
import strutils
proc strutils(a: int): int {.exportpy.} = a * 2 # Issue #95

proc issue196(a: int, b: int, c: int = 3, d: int = 123): bool {.exportpy.} =
  a == 1 and b == 2 and c == 3 and d == 4

iterator testIterator(s: string): int {.exportpy.} =
  for i in 0 ..< s.len:
    yield i

# Exporting classes
type TestType = ref object of PyNimObjectExperimental
  myField: string

proc newTestType(arg: string): TestType {.exportpy.} =
  TestType(myField: arg)

proc setMyField(self: TestType, value: string) {.exportpy.} =
  self.myField = value

proc getMyField(self: TestType): string {.exportpy.} =
  self.myField

type AnotherTestType = ref object of PyNimObjectExperimental
  myIntField: int

proc setMyField(self: AnotherTestType, value: int) {.exportpy.} =
  self.myIntField = value

proc setMyFieldFromTt(self: AnotherTestType, value: TestType) {.exportpy.} =
  self.myIntField = parseInt(value.myField)

proc getMyField(self: AnotherTestType): int {.exportpy.} =
  self.myIntField

# Raising Defects

proc assertFalse(): void {.exportpy} =
    # AssertionDefect
    doAssert false

proc invalidIndex(): int {.exportpy} =
    # IndexDefect
    let mySequence = @[1, 2, 3]
    mySequence[4]

proc endOfFile(): char {.exportpy} =
    # EOFError
    let file = open("/dev/null", fmRead)
    readChar(file)

proc readImpossibleFile(): void {.exportpy} =
    # IOError
    discard open("/dev/null/impossible", fmRead)

proc invalidKey(): string {.exportpy} =
    # KeyError
    let myTable = {1: "one", 2: "two"}.toTable
    myTable[3]

proc invalidObjectConversion(): void {.exportpy} =
    # ObjectConversionDefect
    raise newException(ObjectConversionDefect, "Generic ObjectConversionDefect")

proc intDivideByZero(): int {.exportpy} =
    # DivByZeroDefect
    1 mod 0

proc floatDivideByZero(): float {.exportpy} =
    # FloatDivByZeroDefect
    raise newException(FloatDivByZeroDefect, "Generic FloatDivByZeroDefect")

proc genericFloatingPointDefect(): float {.exportpy} =
    # FloatOverflowDefect of FloatingPointDefect
    1 / 0

proc readFakeLibrary(): void {.exportpy} =
    # LibraryError
    discard checkedSymAddr(nil, "fake_library")

proc stackOverflow(): void {.exportpy} =
    # StackOverflowDefect
    raise newException(StackOverflowDefect, "Generic StackOverflowDefect")

proc osError(): void {.exportpy} =
    # OSError
    raise newException(OSError, "Generic OSError")

proc outOfMemory(): void {.exportpy} =
    # OutOfMemDefect
    raise newException(OutOfMemDefect, "Generic OutOfMemDefect")

