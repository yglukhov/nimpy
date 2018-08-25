
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
import sys
assert(len(sys.argv) > 0)
