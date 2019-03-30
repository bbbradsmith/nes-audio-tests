#
# filtermatch.py
#

#
# Some very rough tests to estimate a highpass filter
# from step response.
#
# The "10hz" WAVs are a 10 Hz square wave cut to begin at the first high sample.
# The "pop" WAVs have a single positive pop from 0 to high somewhere in the middle.
#
# This program tries random variations of filter settings to try and best match
# the given input. The results aren't good enough to be directly usable
# but with some probing and changing of parameters it can find some
# good information to use as a starting point for modelling the highpass.
#

import wave
import struct
import matplotlib.pyplot as pyplot
import math
import random
import scipy.signal

sr = 0

def normalize(w, trim=0):
    m = max(max(w[trim:]),-min(w[trim:]))
    r = 1
    if m != 0:
        r = 1/m
    return [x*r for x in w]

def ideal_square(w):
    o = []
    for v in w:
        if v > 0:
            o.append(1)
        else:
            o.append(-1)
    return o

def ideal_step(w,t):
    o = []
    s = 0
    for v in w:
        if v > t:
            s = 1
        o.append(s)
    return o

def highpass(w,cutoff,trim=0):
    rc = 1 / (2 * math.pi * cutoff)
    alpha = rc / (rc + (1 / sr))
    o = []
    pw = w[0]
    po = w[0]
    for vw in w:
        vo = alpha * ( po + vw - pw )
        o.append(vo)
        pw = vw
        po = vo
    return normalize(o,trim)

def highpass_butter(w,cutoff,order,trim=0):
    global sr
    bcut = cutoff / (sr * 0.5)
    (b,a) = scipy.signal.butter(order,bcut,"highpass")
    return scipy.signal.lfilter(b, a, w)

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
    return normalize(ws)

def square_diff(w,o):
    return math.fsum([(x-y)**2 for (x,y) in zip(w,o)])

attempts = []

def find1d(w, s, func, low, high, iterations, trim=0, shrink=0.9, sub_iters=30):
    global attempts
    best_m = low
    best_d = -1
    for i in range(iterations):
        for j in range(sub_iters):
            m = random.uniform(low,high)
            om = func(s,m,trim)
            od = square_diff(w[trim:],om[trim:])
            attempts.append((m,od))
            if best_d < 0 or (od < best_d):
                best_d = od
                best_m = m
        low = ((low-best_m) * shrink) + best_m
        high = ((high-best_m) * shrink) + best_m
        print("iteration %d: %f (%f, %f)" % (i,best_m,low,high))
    return best_m

def find2d(w, s, func, low, high, iterations, trim=0, shrink=0.9, sub_iters=90):
    global attempts
    best_m = low
    best_d = -1
    for i in range(iterations):
        for j in range(sub_iters):
            m0 = random.uniform(low[0],high[0])
            m1 = random.uniform(low[1],high[1])
            m = (m0, m1)
            om = func(s,m,trim)
            od = square_diff(w[trim:],om[trim:])
            attempts.append((m0,m1,od))
            if best_d < 0 or (od < best_d):
                best_d = od
                best_m = m
        low0  = (( low[0]-best_m[0]) * shrink) + best_m[0]
        high0 = ((high[0]-best_m[0]) * shrink) + best_m[0]
        low1  = (( low[1]-best_m[1]) * shrink) + best_m[1]
        high1 = ((high[1]-best_m[1]) * shrink) + best_m[1]
        low  = ( low0,  low1)
        high = (high0, high1)
        print("iteration %d: %f, %f (%f, %f) - (%f, %f)" % (i,best_m[0],best_m[1],low[0],low[1],high[0],high[1]))
    return best_m

w = loadwave("10hz_ftp_cut2.wav")
s = ideal_square(w)
trim = 20000
#cutoff_ftp = find1d(w,s,highpass,7,7.2,100,trim)
cutoff_ftp = 7.110830
h = highpass(s,cutoff_ftp,trim)
pyplot.plot(s,alpha=0.5)
pyplot.plot(w,alpha=0.5)
pyplot.plot(h,alpha=0.5)
pyplot.title("FastTrackPro highpass cutoff = %fhz" % cutoff_ftp)
#pyplot.show()
pyplot.close()

def filter_apu_famicom(s,c,trim=0):
    global cutoff_ftp
    #h = highpass_butterworth(s,c,2,trim)
    h = highpass(s,c,trim)
    #h = highpass(s,c[0],trim)
    #h = highpass(h,c[1],trim)
    h = highpass(h,cutoff_ftp,trim)
    return h
w = loadwave("pop_apu_famicom.wav")
s = ideal_step(w,0.05)
trim = 0
cutoff_apu_famicom = find1d(w,s,filter_apu_famicom,0.001,400,25,trim)
#cutoff_apu_famicom = find2d(w,s,filter_apu_famicom,(1,1),(100,100),25,trim)
h = filter_apu_famicom(s,cutoff_apu_famicom,trim)
pyplot.plot(s,alpha=0.5)
pyplot.plot(w,alpha=0.5)
pyplot.plot(h,alpha=0.5)
pyplot.title("APU Famicom step (+ FTP) cutoff = %fhz" % cutoff_apu_famicom)
pyplot.show()
pyplot.close()


##def filter_apu(s,c,trim=0):
##    global cutoff_ftp
##    h = highpass(s,c[0],trim)
##    h = highpass(s,c[1],trim)
##    h = highpass(h,cutoff_ftp,trim)
##    return h
##w = loadwave("pop_apu_nes.wav")
##s = ideal_step(w,0.05)
##trim = 0
##cutoff_apu = find2d(w,s,filter_apu,(70,400),(110,500),25,trim,0.95,50)
###cutoff_apu = 10
##h = filter_apu(s,cutoff_apu,trim)
##pyplot.plot(s,alpha=0.5)
##pyplot.plot(w,alpha=0.5)
##pyplot.plot(h,alpha=0.5)
###pyplot.title("APU pop (+ FTP) cutoff = %fhz" % cutoff_apu)
##pyplot.title("APU pop (+ FTP) cutoff = %fhz, %fhz" % (cutoff_apu[0],cutoff_apu[1]))
##pyplot.show()
##pyplot.close()

##def filter_5b(s,c,trim=0):
##    global cutoff_ftp
##    h = highpass_butterworth(s,c,2,trim)
##    h = highpass(h,cutoff_ftp,trim)
##    return h
##w = loadwave("pop_5B_5B.wav")
##s = ideal_step(w,0.05)
##trim = 0
###cutoff_5b = find2d(w,s,filter_5b,(0.01,0.01),(8,8),20,trim)
###cutoff_5b = find1d(w,s,filter_5b,0.01,10,20,trim)
##cutoff_5b = 6
##h = filter_5b(s,cutoff_5b,trim)
##pyplot.plot(s,alpha=0.5)
##pyplot.plot(w,alpha=0.5)
##pyplot.plot(h,alpha=0.5)
###pyplot.title("5B pop (+ FTP) cutoff = %fhz, %fhz" % (cutoff_5b[0], cutoff_5b[1]))
##pyplot.title("5B pop (+ FTP) cutoff = %fhz" % cutoff_5b)
##pyplot.show()
##pyplot.close()

pyplot.scatter(*zip(*attempts),marker="x")
pyplot.show()
