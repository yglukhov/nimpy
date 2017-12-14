import ../python

proc greet(name: string): string {.exportpy.} =
    return "Hello, " & name & "!"

proc somethingThatReturnsNilString(): string {.exportpy.} =
    discard
