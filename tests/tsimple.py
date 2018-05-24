import simple,cmath
assert(simple.greet("world") == "Hello, world!")
assert(simple.somethingThatReturnsNilString() == None)
assert(simple.sumInts(4, 5) == 9)
assert(abs(simple.sumFloats(4.1, 5.2) - 9.3) < 0.0001)
assert(abs(simple.sumAssorted(1, 2, 3, 4, 5, 6, 7) - 28) < 0.0001)
assert(simple.sumIntsInArray([1, 2, 3, 4, 5, 6, 7]) == 28)
assert(simple.reverseArray([1, 2, 3]) == [3, 2, 1])
assert(simple.reverseVec3([1, 2, 3]) == [3, 2, 1])
assert(simple.flipBool(False) == True)
assert(simple.flipBool(True) == False)

assert(simple.complexSqrt(complex(1, -1)) == cmath.sqrt(complex(1, -1)))
assert(simple.complexSeqSqrt([complex(1, -1), complex(1, 1)]) == [cmath.sqrt(complex(1, -1)), cmath.sqrt(complex(1, 1))])

assert(simple.sum_ints(3, 4) == 7)

assert(simple.TestType() != None)

assert(simple.getMyObj()["a"] == 5)
assert(simple.getMyObj()["c"] == "hello")
assert(simple.validateMyObj(simple.getMyObj()))

simple.voidProc()

print("Tests complete!")
