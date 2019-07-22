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
ADJUST = True # relative graph rather than absolute, easier to evaluate

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
        rms = rms_test(w,test_pos,swindow)
        i0 = i & 15
        i1 = i >> 4
        results[i0].append(rms)
        #print("%2d,%2d = %8.4f (%d,%d)" % (i0,i1,rms,int(test_pos),int(swindow)))
    # cache results and return
    numpy.savetxt(cache_filename,results)
    return results

def dac_square_linear():
    return [[y+x for x in range(16)] for y in range(16)]

def squ_blargg(s0,s1):
    if s0 == 0 and s1 == 0:
        return 0
    return 95.88 / ((8128 / (s0 + s1)) + 100)

def dac_square_blargg():
    return [[squ_blargg(y,x) for x in range(16)] for y in range(16)]

def dac_square_normalize(results):
    # normalize based on average of single square at full volume
    m = (results[0][15] + results[15][0]) / 2
    return [[v/m for v in row] for row in results]

def dac_square_plot(results, colour):
    graph = dac_square_normalize(results)
    # plot results
    for i in range(len(graph)):
        gy = graph[i]
        gx = [r+i for r in range(len(gy))]
        if ADJUST:
            gy = [graph[i][r]*(15/max(r+i,1)) for r in range(16)]
            if i == 0: # skip zeroes
                gy = gy[1:]
                gx = gx[1:]
        pyplot.plot(gx,gy,color=colour,linewidth=0.5,label="%d"%i)

# graph of how symmetrical the output is (i.e. are the two squares identical)
# each element in the table is compared to the average of its diagonal
def dac_square_symmetry(name, results):
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

#
# dac_tnd_common
#

def tnd_blargg(t, n, d):
    if t == 0 and n == 0 and d == 0:
        return 0
    return 159.79 / ((1 / ((t/8227) + (n/12241) + (d/22638))) + 100)

#
# dac_tnd0
#

def dac_tnd0(filename, start, end):
    print("dac_tnd0('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence,
    #             ref triangle, 1st sim triangle, 4th sim triangle,
    #             noise 1, noise 15, sim noise 1, sim noise 15,
    #             ref apu, sim 440 1, sim 440 127
    reference = [ 1068974, 24667483, 1748973,
                  1164902, 1284676, 1644415,
                  1836025, 3513115, 3633885, 5335652,
                  9206205, 9325902, 24512552 ]
    reference = remap_reference(reference, start, end)
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.npy" % (start,end)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.load(cache_filename)
    # load waveform and calculate test positions
    (w,sr) = loadwave(filename)
    silence = reference[2]
    reftri = reference[3]
    dmctri1 = reference[4]
    dmctri4 = reference[5]
    noise1 = reference[6]
    noise15 = reference[7]
    dmcnoise1 = reference[8]
    dmcnoise15 = reference[9]
    refsquare = reference[10]
    dmcsquare1 = reference[11]
    dmcsquare127 = reference[12]
    swindow = sr # 1 second
    swindow = int ( (swindow / (sr/BASE_FREQ)) * (sr/BASE_FREQ) ) # snap to nearest period of waveform 
    # read tests
    baseline = rms_test(w, silence, sr)
    refs = [
        rms_test(w, reftri, swindow),
        rms_test(w, refsquare, swindow) ]
    results = [[],[],[],[],refs]
    for i in range(4):
        stest = (dmctri4-dmctri1)/3
        test_pos = dmctri1 + (i * stest)
        rms = rms_test(w,test_pos,swindow)
        results[0].append(rms)
    for i in range(15):
        stest = (noise15-noise1)/14
        test_pos = noise1 + (i * stest)
        rms = rms_test(w,test_pos,swindow)
        results[1].append(rms)
        stest = (dmcnoise15-dmcnoise1)/14
        test_pos = dmcnoise1 + (i * stest)
        rms = rms_test(w,test_pos,swindow)
        results[2].append(rms)
    for i in range(127):
        stest = (dmcsquare127-dmcsquare1)/126
        test_pos = dmcsquare1 + (i * stest)
        rms = rms_test(w,test_pos,swindow)
        results[3].append(rms)
    # cache results and return
    numpy.save(cache_filename,results)
    return results

def dac_tnd0_blargg():
    refs = [
        tnd_blargg(15,0,0)-tnd_blargg(0,0,0),
        squ_blargg(15,0)-squ_blargg(0,0) ]
    results = [[],[],[],[],refs]
    for i in range(4):
        results[0].append(tnd_blargg(7.5,0,15<<i)-tnd_blargg(7.5,0,0))
    for i in range(15):
        results[1].append(tnd_blargg(7.5,i+1,0)-tnd_blargg(7.5,0,0))
        results[2].append(tnd_blargg(7.5,0,(i+1)*8)-tnd_blargg(7.5,0,0))
    for i in range(127):
        results[3].append(tnd_blargg(7.5,0,i+1)-tnd_blargg(7.5,0,0))
    return results

def dac_tnd0_normalize(results):
    # normalize to references
    ma = results[4][0] # triangle reference
    mb = results[1][14] # noise reference
    mc = mb # noise reference
    md = results[3][126] # maximum volume reference
    a = [v/ma for v in results[0]]
    b = [v/mb for v in results[1]]
    c = [v/mc for v in results[2]]
    d = [v/md for v in results[3]]
    e = results[4]
    return [a,b,c,d,e]

def dac_tnd0_plot_a(results, colour):
    graph = dac_tnd0_normalize(results)
    gy = graph[0]
    gx = [r for r in range(len(gy))]
    pyplot.plot(gx,gy,color=colour,linewidth=1)

def dac_tnd0_plot_b(results, colour):
    graph = dac_tnd0_normalize(results)
    gy = graph[1]
    gx = [r+1 for r in range(len(gy))]
    pyplot.plot(gx,gy,color=colour,linewidth=1,label="noise")
    gy = graph[2]
    gx = [r+16 for r in range(len(gy))]
    pyplot.plot(gx,gy,color=colour,linewidth=1,label="dmc")

def dac_tnd0_plot_c(results, colour):
    graph = dac_tnd0_normalize(results)
    gy = graph[3]
    gx = [r+1 for r in range(len(gy))]
    pyplot.plot(gx,gy,color=colour,linewidth=1)

#
# dac_tnd1
#

def dac_tnd1(filename, start, end):
    print("dac_tnd1('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence, centre of 1st tone (triangle), center of 2nd tone (noise), centre of last tone (noise) ]
    reference = [ 787498, 38799093, 831480 ,5124435, 5243862, 38716919 ]
    reference = remap_reference(reference, start, end)
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.array" % (start,end)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.loadtxt(cache_filename)
    # load waveform and calculate test positions
    (w,sr) = loadwave(filename)
    silence = reference[2]
    sample0a = reference[3]
    sample0b = reference[4]
    sample127b = reference[5]
    stest = (sample127b-sample0b) / 127 # samples between test gr
    swindow = stest * 1 / 5 # samples per central window of test (1.0 seconds)
    swindow = int ( (swindow / (sr/BASE_FREQ)) * (sr/BASE_FREQ) ) # snap to nearest period of waveform
    # read tests
    baseline = rms_test(w, silence, sr)
    results = [[],[]]
    for i in range(128):
        test_pos_a = sample0a + (i * stest)
        test_pos_b = sample0b + (i * stest)
        rms_a = rms_test(w,test_pos_a,swindow)
        rms_b = rms_test(w,test_pos_b,swindow)
        results[0].append(rms_a)
        results[1].append(rms_b)
        #print("%2d = %8.4f, %8.4f (%d,%d,%d)" % (i,rms_a,rms_b,int(test_pos_a),int(test_pos_b),int(swindow)))
    # cache results and return
    numpy.savetxt(cache_filename,results)
    return results

def dac_tnd1_blargg():
    a = [tnd_blargg(15,0,i)-tnd_blargg(0,0,i) for i in range(128)]
    b = [tnd_blargg(7.5,15,i)-tnd_blargg(7.5,0,i) for i in range(128)]
    return [a, b]

def dac_tnd1_normalize(results):
    # normalize with maximum volume as 1
    ma = results[0][0]
    mb = results[1][0]
    a = [v/ma for v in results[0]]
    b = [v/mb for v in results[1]]
    return [a,b]

def dac_tnd1_plot_a(results, colour):
    graph = dac_tnd1_normalize(results)
    gy = graph[0]
    gx = [r for r in range(len(gy))]
    pyplot.plot(gx,gy,color=colour,linewidth=1)

def dac_tnd1_plot_b(results, colour):
    graph = dac_tnd1_normalize(results)
    gy = graph[1]
    gx = [r for r in range(len(gy))]
    pyplot.plot(gx,gy,color=colour,linewidth=1)

#
# dac_tnd2
#

triangle = [ 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 ]

def dac_tnd2(filename, start, end, phase):
    print("dac_tnd2('%s',%d,%d,%d)" % (filename, start, end, phase))
    # reference [ start, end, 1s of silence, centre of 1st tone (noise), center of 6th tone (dmc noise), centre of last tone (dmc noise) ]
    reference = [ 207853, 26573373, 238912, 377668, 981382, 26443372 ]
    reference = remap_reference(reference, start, end)
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.array" % (start,end)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.loadtxt(cache_filename)
    # load waveform and calculate test positions
    (w,sr) = loadwave(filename)
    silence = reference[2]
    sample0 = reference[3]
    sample5 = reference[4]
    sample197 = reference[5]
    sgroup = (sample197-sample5) / 32 # samples between group (there are 33 groups)
    stest = (sample5-sample0) / 5 # samples between tests within group
    swindow = stest * 1 / 2.5 # samples per central window of test (1.0 seconds)
    swindow = int ( (swindow / (sr/BASE_FREQ)) * (sr/BASE_FREQ) ) # snap to nearest period of waveform
    # read tests
    baseline = rms_test(w, silence, sr)
    results = []
    for j in range(6):
        row = [0] * 16
        for i in range(32):
            test_pos = sample0 + (j * stest) + (i * sgroup)
            rms = rms_test(w,test_pos,swindow)
            tp = triangle[(phase+i)%32]
            row[tp] += rms
            #print("%2d,%2d = %8.4f,%d (%d,%d)" % (j,i,rms,tp,int(test_pos),int(swindow)))
        results.append(row)
    # cache results and return
    numpy.savetxt(cache_filename,results)
    return results

def dac_tnd2_blargg():
    a = [tnd_blargg(i,1,0)-tnd_blargg(i,0,0) for i in range(16)]
    b = [tnd_blargg(i,8,0)-tnd_blargg(i,0,0) for i in range(16)]
    c = [tnd_blargg(i,15,0)-tnd_blargg(i,0,0) for i in range(16)]
    d = [tnd_blargg(i,0,8)-tnd_blargg(i,0,0) for i in range(16)]
    e = [tnd_blargg(i,0,64)-tnd_blargg(i,0,0) for i in range(16)]
    f = [tnd_blargg(i,0,120)-tnd_blargg(i,0,0) for i in range(16)]
    return [a,b,c,d,e,f]

def dac_tnd2_normalize(results):
    # normalize with maximum volume as 1
    mc = results[2][0]
    mf = results[5][0]
    a = [v/mc for v in results[0]]
    b = [v/mc for v in results[1]]
    c = [v/mc for v in results[2]]
    d = [v/mf for v in results[3]]
    e = [v/mf for v in results[4]]
    f = [v/mf for v in results[5]]
    return [a,b,c,d,e,f]

def dac_tnd2_plot_a(results, colour):
    graph = dac_tnd2_normalize(results)
    for i in range(0,3):
        gy = graph[i]
        gx = [r for r in range(len(gy))]
        pyplot.plot(gx,gy,color=colour,linewidth=1,label="%d"%i)

def dac_tnd2_plot_b(results, colour):
    graph = dac_tnd2_normalize(results)
    for i in range(3,6):
        gy = graph[i]
        gx = [r for r in range(len(gy))]
        pyplot.plot(gx,gy,color=colour,linewidth=1,label="%d"%i)

#
# dac_tnd3
#

def dac_tnd3(filename, start, end):
    print("dac_tnd3('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence, centre of 1st tone, center of 15th tone, centre of last tone ]
    reference = [ 399826, 29641830, 433277, 519843, 2197024, 29511148 ]
    reference = remap_reference(reference, start, end)
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.array" % (start,end)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.loadtxt(cache_filename)
    # load waveform and calculate test positions
    (w,sr) = loadwave(filename)
    silence = reference[2]
    sample1 = reference[3]
    sample15 = reference[4]
    sample240 = reference[5]
    sgroup = (sample240-sample15) / 15 # samples per test group
    stest = (sample15-sample1) / 14 # samples per test within group
    swindow = stest * 1.0 / 2.5 # samples per central window of test (1.0 seconds)
    swindow = int ( (swindow / (sr/BASE_FREQ)) * (sr/BASE_FREQ) ) # snap to nearest period of waveform
    # read tests
    baseline = rms_test(w, silence, sr)
    results = []
    for j in range(16):
        row = []
        for i in range(15):
            test_pos = sample1 + (j * sgroup) + (i * stest)
            rms = rms_test(w,test_pos,swindow)
            row.append(rms)
            #print("%2d,%2d = %8.4f (%d,%d)" % (j,i,rms,int(test_pos),int(swindow)))
        results.append(row)
    # cache results and return
    numpy.savetxt(cache_filename,results)
    return results

def dac_tnd3_blargg():
    return [[tnd_blargg(7.5,i+1,j*8)-tnd_blargg(7.5,0,j*8) for i in range(15)] for j in range(16)]

def dac_tnd3_normalize(results):
    # normalize with maximum volume noise as 1
    m = results[0][14]
    return [[v/m for v in row] for row in results]
    
def dac_tnd3_plot(results, colour):
    graph = dac_tnd3_normalize(results)
    # plot results
    for i in range(len(graph)):
        gy = graph[i]
        if ADJUST:
            gy = [graph[i][r]*(15/(r+1)) for r in range(15)]
        gx = [r+1 for r in range(len(gy))]
        pyplot.plot(gx,gy,color=colour,linewidth=1,label="%d"%i)

#
# recordings analyzed
#

square_nes     = dac_square("dac_square_nes.wav", 248593, 31023575)
square_famicom = dac_square("dac_square_famicom.wav", 203497, 30974739)
square_nsfplay = dac_square("dac_square_nsfplay.wav", 16420, 30791622)
square_linear  = dac_square_linear()
square_blargg  = dac_square_blargg()
#dac_square_symmetry("square_nes",square_nes)
#dac_square_symmetry("square_famicom",square_famicom)
#dac_square_symmetry("square_nsfplay",square_nsfplay)
dac_square_plot(square_linear ,"#0000FF")
dac_square_plot(square_blargg ,"#0000FF")
dac_square_plot(square_nsfplay,"#00FFFF")
dac_square_plot(square_famicom,"#00FF00")
dac_square_plot(square_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()

tnd0_nes     = dac_tnd0("dac_tnd0_nes.wav", 1068974, 24667483)
tnd0_blargg  = dac_tnd0_blargg()
dac_tnd0_plot_a(tnd0_blargg ,"#0000FF")
dac_tnd0_plot_a(tnd0_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()
dac_tnd0_plot_b(tnd0_blargg ,"#0000FF")
dac_tnd0_plot_b(tnd0_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()
dac_tnd0_plot_c(tnd0_blargg ,"#0000FF")
dac_tnd0_plot_c(tnd0_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()

tnd1_nes     = dac_tnd1("dac_tnd1_nes.wav", 787498, 38799093)
tnd1_blargg  = dac_tnd1_blargg()
dac_tnd1_plot_a(tnd1_blargg ,"#0000FF")
dac_tnd1_plot_a(tnd1_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()
dac_tnd1_plot_b(tnd1_blargg ,"#0000FF")
dac_tnd1_plot_b(tnd1_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()

tnd2_nes     = dac_tnd2("dac_tnd2_nes.wav", 207853, 26573373, 1)
tnd2_blargg  = dac_tnd2_blargg()
dac_tnd2_plot_a(tnd2_blargg ,"#0000FF")
dac_tnd2_plot_a(tnd2_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()
dac_tnd2_plot_b(tnd2_blargg ,"#0000FF")
dac_tnd2_plot_b(tnd2_nes    ,"#FF0000")
pyplot.show()
pyplot.clf()

tnd3_nes     = dac_tnd3("dac_tnd3_nes.wav", 906118, 30147827)
tnd3_famicom = dac_tnd3("dac_tnd3_famicom.wav", 399826, 29641830)
tnd3_blargg  = dac_tnd3_blargg()
dac_tnd3_plot(tnd3_blargg ,"#0000FF")
dac_tnd3_plot(tnd3_famicom,"#00FF00")
dac_tnd3_plot(tnd3_nes,    "#FF0000")
pyplot.show()
pyplot.clf()
