import ../nimpy

pyExportModule("kwargsmod")

type
  KwArgsObject* = ref object of PyNimObjectExperimental
    value*: int

proc initKwArgsObject*(self: KwArgsObject, value: int = 1) {.exportpy.} =
  self.value = value

proc add*(self: KwArgsObject, a: int, b: int = 10): int {.exportpy.} =
  self.value + a + b

proc pair*(self: KwArgsObject, a: int, b: int): int {.exportpy.} =
  a * 100 + b
