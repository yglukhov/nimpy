import ../nimpy

# The module built from this file is renamed to _mycustommodulename in nimble test

pyExportModule(name = "_mycustommodulename", doc = """
This is the doc
for my module""")

proc hello(): int {.exportpy.} = 5
