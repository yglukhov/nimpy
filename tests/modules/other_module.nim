# Extra module to test exporting multiple modules from Nim
import ../../nimpy

pyExportModule("other_module", doc="Other module docstring")

proc other_proc(): int {.exportpy.} =
  ## Other proc docstring
  result = 9

# All the procs following pyExportModule statement should be exported under the specified module name
pyExportModule("nimfrompy")

proc other_other_proc(): int {.exportpy.} = 5
