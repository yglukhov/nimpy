# Extra module to test exporting multiple modules from Nim
import ../../nimpy

pyExportModule("other_module", doc="Other module docstring")

proc other_proc(): int {.exportpy.} =
  ## Other proc docstring
  result = 9
