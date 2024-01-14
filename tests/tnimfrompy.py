import cmath, os
import nimfrompy as s
import numpytest

assert(s.greet("world") == "Hello, world!")
assert(s.greet("world", "Hello", "!") == "Hello, world!")
assert(s.greet("world", greeting="Hello") == "Hello, world!")
assert(s.greet(name="world", greeting="Hello", suffix="!") == "Hello, world!")
greet_args = ("world", )
greet_kwargs = {'greeting': "Hello", 'suffix': "!"}
assert(s.greet(*greet_args, **greet_kwargs) == "Hello, world!")

try:
  s.greet()
  assert(False)
except TypeError as e:
  expected = "TypeError('greet() takes exactly 3 arguments (0 given)',)"
  assert(expected[:-2] in repr(e))
try:
  s.greet(greeting="Hi")
  assert(False)
except TypeError as e:
  expected = "TypeError('greet() missing 1 required positional argument: name',)"
  assert(expected[:-2] in repr(e))
try:
  s.greet(name="world", invalid="foo")
  assert(False)
except TypeError as e:
  expected = "TypeError('greet() got an unexpected keyword argument invalid',)"
  assert(expected[:-2] in repr(e))
try:
  s.greet("hello", "world", greeting="foo")
  assert(False)
except TypeError as e:
  expected = "TypeError('greet() got multiple values for argument greeting',)"
  assert(expected[:-2] in repr(e))
try:
  s.greet(123)
except TypeError as e:
  expected = "TypeError(\"Can't convert python obj of type 'int' to string\",)"
  assert(expected[:-2] in repr(e))

# Generic exception raising
try:
  s.assertFalse()
except AssertionError as e:
  assert("`false`" in repr(e))
try:
  s.intDivideByZero()
except ZeroDivisionError as e:
  expected = "division by zero"
  assert(expected in repr(e))
try:
  s.floatDivideByZero()
except ZeroDivisionError as e:
  assert (expected in repr(e))

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
assert(s.subtractUints(2**63, 1) == 2**63 - 1)
assert(s.subtractUints(2**63, 0) == 2**63)
assert(s.subtractUints(0xffffffffffffffff, 0) == 0xffffffffffffffff)
assert(s.reverseArray([1, 2, 3]) == [3, 2, 1])
assert(s.reverseArray((1, 2, 3)) == [3, 2, 1]) # Python tuples should be convertible to nim seqs
assert(s.reverseVec3([1, 2, 3]) == [3, 2, 1])
assert(s.reverseVec3((1, 2, 3)) == [3, 2, 1]) # Python tuples should be convertible to nim seqs
assert(s.reverseByteArray([1, 2, 3]) == b"\x03\x02\x01")
assert(s.reverseByteArray(b"\x03\x00\x01\x02") == b"\x02\x01\x00\x03")
assert(s.reverseByteVec3(b"\x03\x00\x01") == b"\x01\x00\x03")
assert(s.reverseByteVec3([3, 0, 1]) == b"\x01\x00\x03")
assert(s.flipBool(False) is True)
assert(s.flipBool(True) is False)

assert(s.complexSqrt(complex(1, -1)) == cmath.sqrt(complex(1, -1)))
assert(s.complexSeqSqrt([complex(1, -1), complex(1, 1)]) == [cmath.sqrt(complex(1, -1)), cmath.sqrt(complex(1, 1))])

assert(s.sum_ints(3, 4) == 7)

assert(s.getTable()["Hello"] == 0)
assert(s.getTable()["SomeKey"] == 10)

assert(s.getIntTable()[0] == 1.0)
assert(s.getIntTable()[1] == 15.0)
assert(s.getIntTable()[10] == 5.0)

dictFromJson = s.getJsonAsDict()
assert(dictFromJson["SomeKey"] == 1.0)
assert(dictFromJson["Another"] == 5)
assert(dictFromJson["Foo"] == [1, 2, 3.5, {"InArray" : 5}])
assert(dictFromJson["Bar"] == { "Nested" : "Value" })

# Test exported type
tt = s.TestType()
tt.setMyField("1234")
assert(tt.getMyField() == "1234")
att = s.AnotherTestType()
att.setMyField(5)
assert(att.getMyField() == 5)
att.setMyFieldFromTt(tt)
assert(att.getMyField() == 1234)
assert(s.newTestType("hi").getMyField() == "hi")

try:
  att.setMyFieldFromTt(123)
except TypeError as e:
  expected = "TypeError('Cannot convert python object to TestType',)"
  assert(expected[:-2] in repr(e))

assert(s.getMyObj()["a"] == 5)
assert(s.getMyObj()["c"] == "hello")
assert(s.validateMyObj(s.getMyObj()))

assert(s.validateMyRefObj(s.getMyRefObj()))
assert(s.getNilObj() is None)
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
assert(s.tupleDiff([5, 4], (2, 3)) == (3, 1)) # Python lists should be convertible to nim tuples

assert(s.testDefaultArgs("hello, ", "world") == s.testDefaultArgs("hello, "))

assert(s.testJsonArgument({"foo": 666, "bar": False, "baz": 42.0}) == "ok")

assert(s.testLambda(lambda x: x + 5) == 8)
assert(s.testLambda2(lambda x: x + 5) == 8)

receivedString = ""
def receiveString(x):
  global receivedString
  receivedString = x
s.testVoidLambda(receiveString)
assert(receivedString == "hello")

assert(s.testNilLambda(None) == True)

assert(s.strutils(5) == 10) # Issue #95

assert(s.issue196(1, b=2, d=4))

numbers = []
for i in s.testIterator("Hello"):
  numbers.append(i)

assert(numbers == [0, 1, 2, 3, 4])

assert(s.other_other_proc() == 5)

s.testPyFromNim()

numpytest.test()

print("Tests complete!")
