import ../nimpy
import algorithm, complex

proc greet(name: string): string {.exportpy.} =
    return "Hello, " & name & "!"

proc somethingThatReturnsNilString(): string {.exportpy.} =
    discard

proc sumInts(a, b: int32): int {.exportpy.} = a + b
proc sumFloats(a, b: float): float {.exportpy.} = a + b
proc sumAssorted(a, b: int32, c: uint8, d: int64, e: float32, f: float64, g: float): float {.exportpy.} =
    a.float + b.float + c.float + d.float + e + f + g
proc sumIntsInArray(a: openarray[int]): int {.exportpy.} =
    for i in a: result += i

proc reverseArray(a: seq[int]): seq[int] {.exportpy.} = a.reversed()
proc reverseVec3(a: array[3, float]): array[3, float] {.exportpy.} = [a[2], a[1], a[0]]
proc flipBool(b: bool): bool {.exportpy.} = not b

proc complexSqrt(x: Complex): Complex {.exportpy.} = sqrt(x)
proc complexSeqSqrt(a: seq[Complex]): seq[Complex] {.exportpy.} =
    result = newSeq[Complex](a.len)
    for i, aa in a: result[i] = sqrt(aa)

proc sumIntsWithCustomName(a, b: int32): int {.exportpy: "sum_ints".} = a + b

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

type TestType = ref object of PyNimObjectBaseToInheritFromForAnExportedType

pyexportTypeExperimental(TestType)
