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

proc reverseArray(a: seq[int]): seq[int] {.exportpy.} = a.reversed()
proc reverseVec3(a: array[3, float]): array[3, float] {.exportpy.} = [a[2], a[1], a[0]]
proc flipBool(b: bool): bool {.exportpy.} = not b

proc complexSqrt(x: Complex): Complex {.exportpy.} = sqrt(x)
proc complexSeqSqrt(a: seq[Complex]): seq[Complex] {.exportpy.} =
    result = newSeq[Complex](a.len)
    for i, aa in a: result[i] = sqrt(aa)

proc sumIntsWithCustomName(a, b: int32): int {.exportpy: "sum_ints".} = a + b

type MyObj = object
    a, b: int
    c: string

proc getMyObj(): MyObj {.exportpy.} =
    result.a = 5
    result.c = "hello"

proc validateMyObj(o: MyObj): bool {.exportpy.} =
    o.a == 5 and o.c == "hello"

proc voidProc() {.exportpy.} =
    discard

type TestType = ref object of PyNimObjectBaseToInheritFromForAnExportedType

pyexportTypeExperimental(TestType)
