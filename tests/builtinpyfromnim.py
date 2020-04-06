import sys

import tbuiltinpyfromnim as s
assert(s.__name__ == "tbuiltinpyfromnim")

assert(s.greet_from_exe("world") == "Hello, world!")
assert(s.greet_from_exe.__doc__ == "This is the docstring")

x = 42

import other_module
assert(other_module.__name__ == "other_module")
assert(other_module.__doc__ == "Other module docstring")
assert(other_module.other_proc() == 9)
assert(other_module.other_proc.__doc__ == "Other proc docstring")
