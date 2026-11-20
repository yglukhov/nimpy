import kwargsmod

obj = kwargsmod.KwArgsObject()
assert obj.add(1) == 12
assert obj.add(a=1) == 12
assert obj.add(1, b=20) == 22
assert obj.add(b=20, a=5) == 26
assert obj.pair(a=2, b=3) == 203

try:
  obj.pair(1, 2, 3)
except TypeError:
  pass
else:
  raise AssertionError("extra positional argument was accepted")
