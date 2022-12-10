#
# dac.py
#
# 1. Record each dac_xxx.nes/nsf test, save as 16-bit mono WAV.
# 2. Each loop of a test begins with a sawtooth buzz.
#    Find the sample position of the end of that buzz (DMC jumps back to 0),
#    one marking the start of the test, and another marking the end of it.
# 3. Run dac_xxx( filename, start, end ) to analyze the test.
#
# tnd2 also has a "phase" parameter for the triangle
# observe the start of the first triangle burst after reset,
# you should find 15 steps down, with a short plateau after the 15th step,
# this is considered starting at phase 1 of 32.
#
# (Each triangle burst advances the phase by 1 step, at the end of the first
# step it has advanced from phase 0 to 1, so the starting phase is 1.)
#
# If reset was not used, the triangle may start at some random phase
# you will have to manually determine.
#

import wave
import struct
import math
import matplotlib.pyplot as pyplot
import numpy
import os.path

BASE_FREQ = 1789772 / 4064 # approximated 440Hz
ADJUST = True # some graphs become relative rather than absolute, easier to evaluate
NOISE_DMC = False # show DMC noise vs noise on graph

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
    return math.sqrt(sum_squares(w,s0,s1)) / width

def remap_reference(reference, start, end):
    ref_start = reference[0]
    ref_end = reference[1]
    rescale = (end - start) / (ref_end - ref_start)
    return [start + ((x-ref_start) * rescale) for x in reference]

def table_1D(graph,name):
    print("index, %s\n" % (name))
    for i in range(len(graph)):
        print("%d, %8.4f" % (i,graph[i]))

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

def plot(gx,gy,colour):
    pyplot.plot(gx,gy,color=colour,linewidth=1)
    #pyplot.scatter(gx,gy,color=colour,s=0.2)

#
# dac_square test
#

def dac_square(filename, start, end):
    print("dac_square('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence, centre of 1st tone, centre of last tone ]
    reference = [ 16420, 30791622, 112420, 232064, 30661055 ]
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

def squ_model(s0,s1,model):
    if s0 == 0 and s1 == 0:
        return 0
    return 1 / ((model / (so + s1)) + 1)

def dac_square_blargg():
    return [[squ_blargg(y,x) for x in range(16)] for y in range(16)]

def dec_square_model(model):
    return [[squ_model(y,x,model) for x in range(16)] for y in range(16)]

def dac_square_normalize(results):
    # normalize based on average of single square at full volume
    m = (results[0][15] + results[15][0]) / 2
    return [[v/m for v in row] for row in results]

def dac_square_plot_a(results, colour):
    # combined overlapping graph of square curves, all combinations mixed
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
        plot(gx,gy,colour)

def dac_square_plot_b(results, colour):
    # simple graph of square curves, isolating both channels
    graph = dac_square_normalize(results)
    gy = graph[0]
    gx = range(len(gy))
    if ADJUST:
        gy = [gy[r] * (15/max(r,1)) for r in range(16)]
        gy = gy[1:]
        gx = gx[1:]
    plot(gx,gy,colour)
    gy = [graph[i][0] for i in range(len(graph))]
    gx = [r+16 for r in range(len(gy))]
    if ADJUST:
        gy = [gy[r] * (15/max(r,1)) for r in range(16)]
        gy = gy[1:]
        gx = gx[1:]
    plot(gx,gy,colour)

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
    if t == 7.5:
        # special case "7.5" is ultrasonic triangle, take average of all values
        accum = 0
        for i in range(0,16):
            accum += tnd_blargg(i,n,d)
        return accum/16
    if t == 0 and n == 0 and d == 0:
        return 0
    return 159.79 / ((1 / ((t/8227) + (n/12241) + (d/22638))) + 100)

def tnd_model(t, n, d, model):
    if t == 7.5:
        accum = 0
        for i in range(0,16):
            accum += tnd_model(i,n,d,model)
        return accum/16
    if t == 0 and n == 0 and d == 0:
        return 0
    return 1 / ((1 / ((t/model[0]) + (n/model[1]) + (d/model[2]))) + 1)

#
# dac_tnd0
#

def dac_tnd0(filename, start, end):
    print("dac_tnd0('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence,
    #             ref triangle, 1st sim triangle, 4th sim triangle,
    #             noise 1, noise 15, sim noise 1, sim noise 127,
    #             ref apu, sim 440 1, sim 440 127
    reference = [ 16420, 33418324, 93220,
                  208013, 327850, 687581,
                  879208, 2556569, 2676516, 17765293,
                  17956832, 18076855, 33263128 ]
    reference = remap_reference(reference, start, end)
    # use cached results if they exist
    cache_filename = filename+"_%d_%d.npy" % (start,end)
    if os.path.exists(cache_filename) and (os.path.getmtime(filename) < os.path.getmtime(cache_filename)):
        return numpy.load(cache_filename,allow_pickle=True)
    # load waveform and calculate test positions
    (w,sr) = loadwave(filename)
    silence = reference[2]
    reftri = reference[3]
    dmctri1 = reference[4]
    dmctri4 = reference[5]
    noise1 = reference[6]
    noise15 = reference[7]
    dmcnoise1 = reference[8]
    dmcnoise127 = reference[9]
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
    for i in range(127):
        stest = (dmcnoise127-dmcnoise1)/126
        test_pos = dmcnoise1 + (i * stest)
        rms = rms_test(w,test_pos,swindow)
        results[2].append(rms)
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
    for i in range(127):
        results[2].append(tnd_blargg(7.5,0,i+1)-tnd_blargg(7.5,0,0))
        results[3].append(tnd_blargg(7.5,0,i+1)-tnd_blargg(7.5,0,0))
    return results

def dac_tnd0_model(model,model_square):
    refs = [
        tnd_model(15,0,0,model)-tnd_model(0,0,0,model),
        squ_model(15,0,model_square)-squ_model(0,0,model_square) ]
    results = [[],[],[],[],refs]
    for i in range(4):
        results[0].append(tnd_model(7.5,0,15<<i,model)-tnd_model(7.5,0,0,model))
    for i in range(15):
        results[1].append(tnd_model(7.5,i+1,0,model)-tnd_model(7.5,0,0,model))
    for i in range(127):
        results[2].append(tnd_model(7.5,0,i+1,model)-tnd_model(7.5,0,0,model))
        results[3].append(tnd_model(7.5,0,i+1,model)-tnd_model(7.5,0,0,model))
    return results

def dac_tnd0_normalize(results):
    # normalize to references
    ma = results[4][0] # triangle reference
    mc = results[2][126] # maximum volume reference
    md = results[3][126] # maximum volume reference
    mb = mc # rescale noise channel to maximum DMC noise volume
    a = [v/ma for v in results[0]]
    b = [v/mb for v in results[1]]
    c = [v/mc for v in results[2]]
    d = [v/md for v in results[3]]
    e = results[4]
    return [a,b,c,d,e]

def dac_tnd0_plot_a(results, colour):
    # four DMC triangle simulated volumes vs. triangle channel
    graph = dac_tnd0_normalize(results)
    gy = graph[0]
    gx = [r for r in range(len(gy))]
    plot(gx,gy,colour)

def dac_tnd0_plot_b(results, colour):
    # 15 noise volumes, 127 DMC noise volumes
    graph = dac_tnd0_normalize(results)
    gy = graph[1]
    gx = [r+1 for r in range(len(gy))]
    if ADJUST and not NOISE_DMC:
        gy = [gy[i] * 15 / gx[i] for i in range(len(gy))]
    plot(gx,gy,colour)
    if NOISE_DMC:
        gy = graph[2]
        gx = [r+16 for r in range(len(gy))]
        plot(gx,gy,colour)

def dac_tnd0_plot_c(results, colour):
    # 127 DMC noise volumes + 127 DMC square volumes (overlapping)
    graph = dac_tnd0_normalize(results)
    gy = graph[2]
    gx = [r+1 for r in range(len(gy))]
    plot(gx,gy,colour)
    gy = graph[3]
    gx = [r+1 for r in range(len(gy))]
    plot(gx,gy,colour)

#
# dac_tnd1
#

def dac_tnd1(filename, start, end):
    print("dac_tnd1('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence,
    #             centre of (2nd group) 1st tone (triangle), center of 2nd tone (noise), centre of last tone (noise) ]
    reference = [ 16421, 38124133, 93220,
                  4449446, 4568922, 38041631 ]
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

def dac_tnd1_model(model):
    a = [tnd_model(15,0,i,model)-tnd_model(0,0,i,model) for i in range(128)]
    b = [tnd_model(7.5,15,i,model)-tnd_model(7.5,0,i,model) for i in range(128)]
    return [a, b]

def dac_tnd1_normalize(results):
    # normalize with maximum volume as 1
    ma = results[0][0]
    mb = results[1][0]
    a = [v/ma for v in results[0]]
    b = [v/mb for v in results[1]]
    return [a,b]

def dac_tnd1_plot_a(results, colour):
    # triangle attenuation due to DMC
    graph = dac_tnd1_normalize(results)
    gy = graph[0]
    gx = [r for r in range(len(gy))]
    plot(gx,gy,colour)

def dac_tnd1_plot_b(results, colour):
    # noise attenuation due to DMC
    graph = dac_tnd1_normalize(results)
    gy = graph[1]
    gx = [r for r in range(len(gy))]
    plot(gx,gy,colour)

#
# dac_tnd2
#

triangle = [ 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 ]

def dac_tnd2(filename, start, end, phase):
    print("dac_tnd2('%s',%d,%d,%d)" % (filename, start, end, phase))
    # reference [ start, end, 1s of silence, centre of 1st tone (noise), center of 6th tone (dmc noise), centre of last tone (dmc noise) ]
    reference = [ 16420, 26293080, 93220, 279723, 878622, 26162901 ]
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

def dac_tnd2_model(model):
    a = [tnd_model(i,1,0,model)-tnd_model(i,0,0,model) for i in range(16)]
    b = [tnd_model(i,8,0,model)-tnd_model(i,0,0,model) for i in range(16)]
    c = [tnd_model(i,15,0,model)-tnd_model(i,0,0,model) for i in range(16)]
    d = [tnd_model(i,0,8,model)-tnd_model(i,0,0,model) for i in range(16)]
    e = [tnd_model(i,0,64,model)-tnd_model(i,0,0,model) for i in range(16)]
    f = [tnd_model(i,0,120,model)-tnd_model(i,0,0,model) for i in range(16)]
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
    # noise attenuation due to triangle
    graph = dac_tnd2_normalize(results)
    for i in range(0,3):
        gy = graph[i]
        gx = [r for r in range(len(gy))]
        plot(gx,gy,colour)

def dac_tnd2_plot_b(results, colour):
    # DMC attenuation due to triangle
    graph = dac_tnd2_normalize(results)
    for i in range(3,6):
        gy = graph[i]
        gx = [r for r in range(len(gy))]
        plot(gx,gy,colour)

#
# dac_tnd3
#

def dac_tnd3(filename, start, end):
    print("dac_tnd3('%s',%d,%d)" % (filename, start, end))
    # reference [ start, end, 1s of silence, centre of 1st tone, center of 15th tone, centre of last tone ]
    reference = [ 16420, 29354192, 93220, 232234, 1909385, 29223805 ] 
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

def dac_tnd3_model(model):
    return [[tnd_model(7.5,i+1,j*8,model)-tnd_model(7.5,0,j*8,model) for i in range(15)] for j in range(16)]

def dac_tnd3_normalize(results):
    # normalize with maximum volume noise as 1
    m = results[0][14]
    return [[v/m for v in row] for row in results]
    
def dac_tnd3_plot(results, colour):
    # noise attenuation (15 levels) due to DMC (16 levels)
    graph = dac_tnd3_normalize(results)
    # plot results
    for i in range(len(graph)):
        gy = graph[i]
        if ADJUST:
            gy = [graph[i][r]*(15/(r+1)) for r in range(15)]
            pass
        gx = [r for r in range(len(gy))]
        plot(gx,gy,colour)

#
# recordings analyzed
#

# collect data

square_nes     = dac_square("dac_square_nes.wav", 474193, 31249139)
square_famicom = dac_square("dac_square_famicom.wav", 251009, 31026263)
square_nsfplay = dac_square("dac_square_nsfplay.wav", 16420, 30791622)
square_linear  = dac_square_linear()
square_blargg  = dac_square_blargg()

tnd0_nes     = dac_tnd0("dac_tnd0_nes.wav", 189264, 33590919)
tnd0_famicom = dac_tnd0("dac_tnd0_famicom.wav", 197219, 33599126)
tnd0_nsfplay = dac_tnd0("dac_tnd0_nsfplay.wav", 16420, 33418324)
tnd0_blargg  = dac_tnd0_blargg()

tnd1_nes     = dac_tnd1("dac_tnd1_nes.wav", 562881, 38670319)
tnd1_famicom = dac_tnd1("dac_tnd1_famicom.wav", 203404, 38311172)
tnd1_nsfplay = dac_tnd1("dac_tnd1_nsfplay.wav", 16421, 38124133)
tnd1_blargg  = dac_tnd1_blargg()

tnd2_nes     = dac_tnd2("dac_tnd2_nes.wav", 363541, 26640001, 1)
tnd2_famicom = dac_tnd2("dac_tnd2_famicom.wav", 354780, 26631487, 1)
tnd2_nsfplay = dac_tnd2("dac_tnd2_nsfplay.wav", 16420, 26293080, 1)
tnd2_blargg  = dac_tnd2_blargg()

tnd3_nes     = dac_tnd3("dac_tnd3_nes.wav", 451682, 29789228)
tnd3_famicom = dac_tnd3("dac_tnd3_famicom.wav", 259986, 29597818)
tnd3_nsfplay = dac_tnd3("dac_tnd3_nsfplay.wav", 16420, 29354192)
tnd3_blargg  = dac_tnd3_blargg()

# construct model



# analyze data

#dac_square_symmetry("square_nes",square_nes)
#dac_square_symmetry("square_famicom",square_famicom)
#dac_square_symmetry("square_nsfplay",square_nsfplay)

dac_square_plot_a(square_linear ,"#0000FF")
dac_square_plot_a(square_blargg ,"#0000FF")
dac_square_plot_a(square_nsfplay,"#00FFFF")
dac_square_plot_a(square_nes    ,"#FF0000")
dac_square_plot_a(square_famicom,"#00FF00")
pyplot.show()
pyplot.clf()

dac_square_plot_b(square_linear ,"#0000FF")
dac_square_plot_b(square_blargg ,"#0000FF")
dac_square_plot_b(square_nsfplay,"#00FFFF")
dac_square_plot_b(square_nes    ,"#FF0000")
dac_square_plot_b(square_famicom,"#00FF00")
pyplot.show()
pyplot.clf()

dac_tnd0_plot_a(tnd0_blargg ,"#0000FF")
dac_tnd0_plot_a(tnd0_nsfplay,"#00FFFF")
dac_tnd0_plot_a(tnd0_nes    ,"#FF0000")
dac_tnd0_plot_a(tnd0_famicom,"#00FF00")
pyplot.show()
pyplot.clf()
dac_tnd0_plot_b(tnd0_blargg ,"#0000FF")
dac_tnd0_plot_b(tnd0_nsfplay,"#00FFFF")
dac_tnd0_plot_b(tnd0_nes    ,"#FF0000")
dac_tnd0_plot_b(tnd0_famicom,"#00FF00")
pyplot.show()
pyplot.clf()
dac_tnd0_plot_c(tnd0_blargg ,"#0000FF")
dac_tnd0_plot_c(tnd0_nsfplay,"#00FFFF")
dac_tnd0_plot_c(tnd0_nes    ,"#FF0000")
dac_tnd0_plot_c(tnd0_famicom,"#00FF00")
pyplot.show()
pyplot.clf()

dac_tnd1_plot_a(tnd1_blargg ,"#0000FF")
dac_tnd1_plot_a(tnd1_nsfplay,"#00FFFF")
dac_tnd1_plot_a(tnd1_nes    ,"#FF0000")
dac_tnd1_plot_a(tnd1_famicom,"#00FF00")
pyplot.show()
pyplot.clf()
dac_tnd1_plot_b(tnd1_blargg ,"#0000FF")
dac_tnd1_plot_b(tnd1_nsfplay,"#00FFFF")
dac_tnd1_plot_b(tnd1_nes    ,"#FF0000")
dac_tnd1_plot_b(tnd1_famicom,"#00FF00")
pyplot.show()
pyplot.clf()

dac_tnd2_plot_a(tnd2_blargg ,"#0000FF")
dac_tnd2_plot_a(tnd2_nsfplay,"#00FFFF")
dac_tnd2_plot_a(tnd2_nes    ,"#FF0000")
dac_tnd2_plot_a(tnd2_famicom,"#00FF00")
pyplot.show()
pyplot.clf()
dac_tnd2_plot_b(tnd2_blargg ,"#0000FF")
dac_tnd2_plot_b(tnd2_nsfplay,"#00FFFF")
dac_tnd2_plot_b(tnd2_nes    ,"#FF0000")
dac_tnd2_plot_b(tnd2_famicom,"#00FF00")
pyplot.show()
pyplot.clf()

dac_tnd3_plot(tnd3_blargg ,"#0000FF")
dac_tnd3_plot(tnd3_nsfplay,"#00FFFF")
dac_tnd3_plot(tnd3_nes,    "#FF0000")
dac_tnd3_plot(tnd3_famicom,"#00FF00")
pyplot.show()
pyplot.clf()
