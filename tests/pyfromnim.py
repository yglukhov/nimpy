
class MyClass(object):
  @staticmethod
  def staticFunc(a, b):
    return a + b

  def someFunc(self, a, b):
    return a - b

  @staticmethod
  def raisingFunc():
    raise Exception("hello")

def test_kwargs(a, b):
  return a - b

def test_dict():
  a = { "Hello" : 0,
      "World" : 1,
      "Yay" : 5 }
  return a

def test_dict_json():
  c = MyClass()
  a = { "Hello" : 0,
      "World" : 1,
      "Yay" : 5.5,
      5 : 10, # non string key converted to string
      "Complex" : complex(-1.0, 2.2),
      "Nested" : {"Dict": 12.7},
      "Object" : c, # NOTE: only converted to string at the moment!
      "List" : [1, 2, 3, 4],
      "ListFloat" : [1.5, 2.2, 3.5, 4.0],
      "ListMixed" : [1, 2.2, 3, 4.0, complex(-1.5, 2.2)],
      "Tuple" : (5.5, 10.0) # converted to `JArray` as well
  }
  return a

def call_callback(fn):
  fn(1, 2, "Hello")

def concat_strings(a, b):
  return a + b

def test_enum1(nimobject):
    return nimobject["e1"]

def test_enum2(nimobject):
    return nimobject["e2"]

def test_enum3(nimobject):
    return nimobject["e3"]

def test_nested_marshalling(nimobject):
    assert(nimobject["a"][2] == 123)
    assert(nimobject["b"][0][1] == 123)
    assert(nimobject["b"][1] == "hello")
    return True

def test_nil_marshalling(nimobj):
    assert(nimobj == None)
    return True

import sys
assert(len(sys.argv) > 0)
