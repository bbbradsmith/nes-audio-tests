#
# dac.py
#
# 1. Record each dac_xxx.nes/nsf test, save as 16-bit mono WAV.
# 2. Each loop of a test begins with a sawtooth buzz.
#    Find the sample position of the end of that buzz (DMC jumps back to 0),
#    one marking the start of the test, and another marking the end of it.
# 3. Run dac_xxx( filename, start, end ) to analyze the test.
#

import wave
import struct
import math
import matplotlib.pyplot as pyplot
import numpy
import os.path

BASE_FREQ = 1789772 / 4064 # approximated 440Hz

#
# utilities
#

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

# recursive summation for numerical stability (s0 to s1 inclusive)
def sum_squares(w, s0, s1):
    if (s0 == s1):
        return w[s0] * w[s0]
    assert(s0 <= s1)
    m = (s0 + s1) // 2
    return sum_squares(w,s0,m) + sum_squares(w,m+1,s1)

def rms_test(w, centre, width):
    s0 = int(centre - (width/2))
    s1 = s0 + int(width) - 1
    return math.sqrt(sum_squares(w,s0,s1))

def remap_reference(reference, start, end):
    ref_start = reference[0]
    ref_end = reference[1]
    rescale = (end - start) / (ref_end - ref_start)
    return [start + ((x-ref_start) * rescale) for x in reference]

def table_2D(graph,yname,xname):
    s = "%s \ %s" % (yname,xname)
    for i in range(len(graph[0])):
        s += ", %2d" % i
    print(s)
    for i in range(len(graph)):
        s = "%2d" % i
        for v in graph[i]:
            s += ", %8.4f" % v
        print(s)

#
# dac_square test
#

def dac_square_normalize(results):
    # normalize based on average of single square at full volume
    m = (results[0][15] + results[15][0]) / 2
    return [[v/m for v in row] for row in results]

def dac_square(filename, start, end):
    print("dac_square('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence, centre of 1st tone, centre of last tone ]
    reference = [ 248593, 31023575, 342288, 464054, 30893207 ]
    reference = remap_reference(reference, start, end)
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.array" % (start,end)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.loadtxt(cache_filename)
    # load waveform and calculate test positions
    (w,sr) = loadwave(filename)
    silence = reference[2]
    sample1 = reference[3]
    sample255 = reference[4]
    stest = (sample255-sample1)/254 # samples per test
    swindow = stest * 1.0 / 2.5 # samples per central window of test (1.0 seconds)
    swindow = int ( (swindow / (sr/BASE_FREQ)) * (sr/BASE_FREQ) ) # snap to nearest period of waveform
    # read tests
    baseline = rms_test(w, silence, sr)
    results = [[] for i in range(16)]
    for i in range(0,256):
        test_pos = ((i-1)*stest)+sample1
        rms = rms_test(w,test_pos,swindow) - baseline
        i0 = i & 15
        i1 = i >> 4
        results[i0].append(rms)
        #print("%2d,%2d = %8.4f (%d,%d)" % (i0,i1,rms,int(test_pos),int(swindow)))
    # cache results and return
    numpy.savetxt(cache_filename,results)
    return results

def dac_square_linear():
    return [[y+x for x in range(16)] for y in range(16)]

def dac_square_blargg():
    return [[min(a+b,1)*95.88/((8128/(a+b+(1-min(a+b,1))))+100) for b in range(16)] for a in range(16)]

def plot_dac_square(results, colour):
    graph = dac_square_normalize(results)
    m = (results[0][15] + results[15][0]) / 2
    graph = [[v/m for v in row] for row in results]
    # plot results
    for i in range(len(graph)):
        gy = graph[i]
        gx = [r+i for r in range(len(gy))]
        pyplot.plot(gx,gy,color=colour,linewidth=0.5,label="%d"%i)

def symmetry_dac_square(name, results):
    print("symmetry_dac_square('%s')" % (name))
    graph = dac_square_normalize(results)
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
    graph = [[graph[i][j]-axis[i+j] for j in range(len(graph[i]))] for i in range(len(graph))]
    table_2D(graph, "Square 0", "Square 1")

square_nes = dac_square("dac_square_nes.wav", 248593, 31023575)
square_famicom = dac_square("dac_square_famicom.wav", 203497, 30974739)
square_nsfplay = dac_square("dac_square_nsfplay.wav", 16420, 30791622)
square_linear = dac_square_linear()
square_blargg = dac_square_blargg()

symmetry_dac_square("square_nes",square_nes)
symmetry_dac_square("square_famicom",square_famicom)
symmetry_dac_square("square_nsfplay",square_nsfplay)

plot_dac_square(square_linear ,"#00FF00")
plot_dac_square(square_blargg ,"#0000FF")
plot_dac_square(square_nsfplay,"#00FFFF")
plot_dac_square(square_famicom,"#FF00FF")
plot_dac_square(square_nes    ,"#FF0000")
pyplot.show()
