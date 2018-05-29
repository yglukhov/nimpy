import ../nimpy

let py = pyBuiltinsModule()
let s = py.sum(py.range(0, 5)).to(int)
doAssert(s == 10)

doAssert(py.sum(py.xrange(0, 5)).to(int) == 10)

echo "cwd: ", pyImport("os").getcwd().to(string)
