import simple

assert(simple.greet("world") == "Hello, world!")
assert(simple.somethingThatReturnsNilString() == None)
assert(simple.sumInts(4, 5) == 9)
assert(abs(simple.sumFloats(4.1, 5.2) - 9.3) < 0.0001)
assert(abs(simple.sumAssorted(1, 2, 3, 4, 5, 6, 7) - 28) < 0.0001)
