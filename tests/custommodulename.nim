import ../nimpy

# The module built from this file is renamed to _mycustommodulename in nimble test

pyExportModuleName("_mycustommodulename")

proc hello(): int {.exportpy.} = 5

