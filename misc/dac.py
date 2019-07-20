#
# dac_square.py
#

#
# 1. Record dac_square.nes/nsf test, save as 16-bit mono WAV.
# 2. Find the centre (sample position) of the first audible test tone.
# 3. Find the centre of the last audible test tone
# 4. Run dac_square( filename, first centre, last centre )
#
# The text result is a comma separated ouput indicating all 256
# combinations of the APU square volumes, and their measured volumes.
# The returned result is a 16x16 2D table of volumes [square 0][square 1].

import wave
import struct
import math
import matplotlib.pyplot as pyplot
import numpy
import os.path

BASE_FREQ = 1789772 / 4064 # approximated 440Hz

def loadwave(filename):
    w = wave.open(filename,"rb")
    global sr
    sr = w.getframerate()
    assert(w.getnchannels() == 1) # "Mono only."
    assert(w.getsampwidth() == 2) # "16-bit only."
    wb = w.readframes(w.getnframes())
    ws = []
    for i in range(0,len(wb),2):
        ws.append(struct.unpack_from("<h",wb,i)[0])
    return (ws,sr)

# recursive summation for numerical stability
def sum_squares(w, s0, s1):
    if (s0 == s1):
        return w[s0] * w[s0]
    assert(s0 <= s1)
    m = (s0 + s1) // 2
    return sum_squares(w,s0,m) + sum_squares(w,m+1,s1)

def dac_square(filename, sample1, sample255):
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.array" % (sample1,sample255)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.loadtxt(cache_filename)
    # load waveform and measure tests
    (w,sr) = loadwave(filename)
    stest = (sample255-sample1)/254 # samples per test
    swindow = stest * 1.0 / 2.5 # samples per central window of test (1.0 seconds)
    swindow = int ( (swindow / (sr/BASE_FREQ)) * (sr/BASE_FREQ) ) # snap to nearest period of waveform
    print('dac_square("%s",%d,%d)' % (filename,sample1,sample255))
    print("square0, square1, RMS")
    graph = [[] for i in range(16)]
    for i in range(0,256):
        test_mid = ((i-1)*stest)+sample1
        test_start = int(test_mid-(swindow/2))
        test_end = test_start + swindow
        ssq = sum_squares(w,test_start,test_end-1)
        rms = math.sqrt( ssq / swindow )
        s0 = i & 15
        s1 = i >> 4
        print("%d, %d, %f" % (s0,s1,rms))
        #print("%d, %d, %f (%d - %d)" % (s0,s1,rms,test_start,test_end+1))
        graph[s0].append(rms)
    numpy.savetxt(cache_filename,graph) # cache results
    return graph

def normalize(graph):
    # normalize based on maximum:
    #m = graph[0][0]
    #for g in graph:
    #    for v in g:
    #        if v > m:
    #            m = v
    # normalize based on average of 1 square at full volume
    m = (graph[0][15] + graph[15][0]) / 2
    return [[v/m for v in row] for row in graph]

def table(graph):
    s = "Square 0 \ Square 1"
    for i in range(len(graph[0])):
        s += ", %2d" % i
    print(s)
    for i in range(len(graph)):
        s = "%2d" % i
        for v in graph[i]:
            s += ", %8.4f" % v
        print(s)

def symmetry(graph):
    assert(len(graph)==len(graph[0]))
    axis = []
    for i in range((len(graph)*2)-1):
        accum = 0
        count = 0
        for j in range(len(graph)):
            if ((i-j) < 0) or ((i-j) >= len(graph)):
                continue
            accum += graph[i-j][j]
            count += 1
        axis.append(accum/count)
    return [[graph[i][j]-axis[i+j] for j in range(len(graph[i]))] for i in range(len(graph))]

def plot(graph, color, normalized=True):
    if normalized:
        graph = normalize(graph)
    for i in range(len(graph)):
        gy = graph[i]
        gx = [r+i for r in range(len(gy))]
        pyplot.plot(gx,gy,color=color,linewidth=0.5,label="%d"%i)

gl = [[a+b for b in range(16)] for a in range(16)] # linear
gb = [[min(a+b,1)*95.88/((8128/(a+b+(1-min(a+b,1))))+100) for b in range(16)] for a in range(16)] # blargg
g1 = dac_square("dac_square.wav",232766,30658550)

table(normalize(g1))
table(symmetry(normalize(g1)))

plot(gl, "#00FF00")
plot(gb, "#0000FF")
plot(g1, "#FF0000")
pyplot.show()
