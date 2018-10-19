# raise all mapped exceptions in Python

def testOSError():
    raise(OSError)

def testIOError():
    raise(IOError)

def testValueError():
    raise(ValueError)

def testKeyError():
    raise(KeyError)

def testEOFError():
    raise(EOFError)

def testArithmeticError():
    raise(ArithmeticError)

def testZeroDivisionError():
    raise(ZeroDivisionError)

def testOverflowError():
    raise(OverflowError)

def testAssertionError():
    raise(AssertionError)

def testMemoryError():
    raise(MemoryError)

def testIndexError():
    raise(IndexError)

def testFloatingPointError():
    raise(FloatingPointError)

def testException():
    raise(Exception)

def testUnsupportedException():
    # example for an unsupported Python exception
    raise(NotImplementedError)
