
# The _mycustommodulename module is built from custommodulename.nim file
import _mycustommodulename
assert(_mycustommodulename.hello() == 5)
assert(_mycustommodulename.__doc__ == """This is the doc
for my module""")
