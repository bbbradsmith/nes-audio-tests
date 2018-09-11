#!/usr/bin/env python3
import sys
assert sys.version_info[0] >= 3, "Python 3 required."

import math

def build_sine(output,size):
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
        table.append(best)
    return table

def assemble_table(table, name, columns):
    s = "; generated table: " + name
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
    s += "\n; end of table\n"
    print(s)
    return s

def write_table(table, filename, columns):
    s = assemble_table(table, filename, columns)
    open(filename,"wt").write(s)

def linear_5b(entries):
    # using tables to mix 3 channels to combine into something as close to linear as we can manage
    base = [10**(3*x/20) for x in range(0,16)] # 3db per step
    def mix(a,b,c):
        return base[a] + base[b] + base[c]
    r0 = mix(0,0,0)
    r1 = mix(13,0,0)
    table = []
    output = []
    for t in range(0,entries):
        target = r0 + (r1-r0) * (t / (entries-1))
        best = (0,0,0)
        best_diff = abs(mix(0,0,0) - target)
        for i in range(15,-1,-1):
            for j in range(0,max(i-2,1)):
                for k in range(0,max(j-2,1)):
                    # note the - on the ranges keeps each channel exponentially quieter:
                    # this is done to mitigate differences between the theoretical
                    # linear mix, and the actual mix of the 3 channels.
                    diff = abs(mix(i,j,k) - target)
                    if diff < best_diff:
                        best = (i,j,k)
                        best_diff = diff
        table.append(best)
        output.append(mix(*best))
    return (table, output)

output_dmc = range(0,0x80) # assuming linear DMC
write_table(build_sine(output_dmc,256),"sine_dmc.inc",16)

(table_5b, output_5b) = linear_5b(64)
sine_5b = build_sine(output_5b, 256)
s = assemble_table(sine_5b, "sine_5b", 16)
tables_5b = list(zip(*table_5b))
s += assemble_table(tables_5b[0],"mix_5b_0", 16)
s += assemble_table(tables_5b[1],"mix_5b_1", 16)
s += assemble_table(tables_5b[2],"mix_5b_2", 16)
open("sine_5b.inc","wt").write(s)

##import matplotlib.pyplot as plt
##o = [output_5b[x] for x in sine_5b]
##plt.plot(o)
##plt.show()
