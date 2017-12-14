import ../python

proc greet(name: string): string {.exportpy.} =
    return "Hello, " & name & "!"

proc somethingThatReturnsNilString(): string {.exportpy.} =
    discard

proc sumInts(a, b: int32): int {.exportpy.} = a + b
proc sumFloats(a, b: float): float {.exportpy.} = a + b
proc sumAssorted(a, b: int32, c: int, d: int64, e: float32, f: float64, g: float): float {.exportpy.} =
    a.float + b.float + c.float + d.float + e + f + g
