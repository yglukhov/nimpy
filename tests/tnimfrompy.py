import cmath, os
import nimfrompy as s

assert(s.greet("world") == "Hello, world!")
assert(s.greetEveryoneExceptJack("world") == "Hello, world!")
try:
    s.greetEveryoneExceptJack("Jack")
    assert False, "Expected s.greetEveryoneExceptJack to throw JackError."
except s.NimPyException as e:
    assert "Cannot greet Jack" in repr(e)
    assert "JackError" in repr(e)
assert(s.somethingThatReturnsEmptyString() == "")
assert(s.sumInts(4, 5) == 9)
assert(abs(s.sumFloats(4.1, 5.2) - 9.3) < 0.0001)
assert(abs(s.sumAssorted(1, 2, 3, 4, 5, 6, 7) - 28) < 0.0001)
assert(s.sumIntsInArray([1, 2, 3, 4, 5, 6, 7]) == 28)
assert(s.reverseArray([1, 2, 3]) == [3, 2, 1])
assert(s.reverseVec3([1, 2, 3]) == [3, 2, 1])
assert(s.flipBool(False) == True)
assert(s.flipBool(True) == False)

assert(s.complexSqrt(complex(1, -1)) == cmath.sqrt(complex(1, -1)))
assert(s.complexSeqSqrt([complex(1, -1), complex(1, 1)]) == [cmath.sqrt(complex(1, -1)), cmath.sqrt(complex(1, 1))])

assert(s.sum_ints(3, 4) == 7)

assert(s.getTable()["Hello"] == 0)
assert(s.getTable()["SomeKey"] == 10)

assert(s.getIntTable()[0] == 1.0)
assert(s.getIntTable()[1] == 15.0)
assert(s.getIntTable()[10] == 5.0)

assert(s.TestType() != None)

assert(s.getMyObj()["a"] == 5)
assert(s.getMyObj()["c"] == "hello")
assert(s.validateMyObj(s.getMyObj()))

assert(s.validateMyRefObj(s.getMyRefObj()))
assert(s.getNilObj() == None)
assert(s.validateNilObj(s.getNilObj()))

s.voidProc()

excMsg = ""
try:
    print(s.sumInts(1, 2, 3))
except TypeError as e:
    excMsg = str(e)

assert(excMsg == "sumInts() takes exactly 2 arguments (3 given)")

assert(s.someFunc1(__builtins__) == 10)
assert(s.someFunc2(__builtins__) == 10)

assert(s.someFunc3() == os.getcwd())

assert(s.tupleDiff((5, 4), (2, 3)) == (3, 1))

assert(s.testDefaultArgs("hello, ", "world") == s.testDefaultArgs("hello, "))

assert(s.testJsonArgument({"foo": 666, "bar": False, "baz": 42.0}) == "ok")

s.testPyFromNim()

print("Tests complete!")
