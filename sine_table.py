#!/usr/bin/env python3
import sys
assert sys.version_info[0] >= 3, "Python 3 required."

import math

output_dmc = range(0,0x80) # assuming linear DMC
output_5b  = [2**(x/2) for x in range(0,13)] # ~3db per step, skipping 0, stopping at 13

def build_sine(output,offset,size):
    table = []
    s0 = min(output)
    s1 = max(output)
    magnitude = (s1 - s0) / 2
    zero = (s0 + s1) / 2
    for i in range(0,size):
        s = (math.sin(i * math.pi * 2 / size) * magnitude) + zero
        best = 0
        best_diff = abs(s - output[0])
        for j in range(1,len(output)):
            diff = abs(s - output[j])
            if diff < best_diff:
                best = j
                best_diff = diff
        table.append(best + offset)
    return table

def save_table(table, filename, columns):
    s = "; generated table: " + filename
    c = 0
    for v in table:
        if c == 0:
            s += "\n.byte "
        else:
            s += ", "
        s += "%3d" % v
        c += 1
        if (c >= columns):
            c = 0
    s += "\n; end of file\n"
    open(filename,"wt").write(s)
    print(s)

save_table(build_sine(output_dmc,0,256),"sine_dmc.inc",16)
save_table(build_sine(output_5b, 1,256),"sine_5b.inc", 16)
