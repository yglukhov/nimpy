{.push stack_trace: off, profiler:off.}
proc rawoutput(s: string) = discard
proc panic(s: string) = rawoutput(s)
# proc rawWrite(f: CFilePtr, s: cstring) {.compilerproc, nonreloadable, hcrInline.} =
#   # we cannot throw an exception here!
#   discard
#   # discard c_fwrite(s, 1, s.len, f)
{.pop.}
