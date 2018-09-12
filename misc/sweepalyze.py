#
# Was used to analyze sweep_5b results.
#

import wave
import struct
from matplotlib import pyplot
import matplotlib
import scipy.signal
import scipy.fftpack
import numpy
import math

fftw = 1<<17
sr = 0

def normalize(w, trim=0):
    m = max(max(w[trim:]),-min(w[trim:]))
    r = 1
    if m != 0:
        r = 1/m
    return [x*r for x in w]

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

def sweepalyze(w,points):
    window = scipy.signal.get_window("blackman",fftw)
    c0 = fftw // 2
    c1 = len(w) - (fftw // 2)
    o = []
    for i in range(0,points):
        c = c0 + int((c1-c0) * i / (points-1))
        ww = w[c-(fftw//2):c+(fftw//2)]
        f = scipy.fftpack.fft(ww * window)
        fm = [abs(x) for x in f[0:fftw//2]]
        fm[0] = 0 #discard DC offset
        primary = numpy.argmax(fm)
        #mag = fm[primary] # this has a bias against higher frequencies (-3db/octave based on window size?)
        mag = numpy.sqrt(numpy.mean(numpy.square(ww*window))) # RMS
        global sr
        time = c / sr
        freq = (sr / fftw) * primary
        if freq != 0:
            o.append((time,freq,mag))
    return o

def normaldb(m):
    zero = max(m)
    return [x-zero for x in m]

legends = []

def plot_finish(dbr=-60,fp0=0,fp1=13):
    pyplot.grid(True)
    pyplot.xscale('log')
    pyplot.gca().xaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
    pyplot.xticks([2**x for x in range(fp0,fp1)])
    pyplot.xlabel('Hz')
    pyplot.yticks(range(dbr,3,3))
    pyplot.ylabel('dB')
    global legends
    if len(legends) > 0:
        pyplot.legend(legends,loc='lower right')
    pyplot.show()
    legends = []

def plot(filename,name=None,points=1000,trim0=0,trim1=-1,color='#000000',alpha=0.75):
    global legends
    print("plot(%s)" % filename)
    if trim1 < 0:
        trim1 = points
    w = loadwave(filename)
    a = sweepalyze(w,points)
    linf = [x[1] for x in a]
    logm = [20*math.log10(x[2]) for x in a]
    pyplot.scatter(linf[trim0:trim1],normaldb(logm[trim0:trim1]),s=5,c=color,alpha=alpha)
    if name == None:
        name = filename
    legends.append(name)

def test(filename,points=1000,trim0=0,trim1=-1):
    if trim1 < 0:
        trim1 = points
    w = loadwave(filename)
    a = sweepalyze(w,points)
    linf = [x[1] for x in a]
    logf = [math.log(x[1]) for x in a]
    logm = [20*math.log10(x[2]) for x in a]
    pyplot.plot(logf) # log frequency vs. sample index
    pyplot.show()
    pyplot.plot(logm) # log magnitude vs. sample index
    pyplot.show()
    pyplot.scatter(linf[trim0:trim1],normaldb(logm[trim0:trim1]),s=5,c='#FF0000')
    plot_finish() # scatter plot showing the resulting freq/db graph

# test() each WAV to be graphed with the desired fftw and number of points,
# then look at the first two graphs produced (log frequency, db)
# find the points where the detected frequency begin/ends matching the sweep
# and use those as the two trim parameters.
# Once finished finding the trim points, use plot() to make a combined graph.

#test("sweep_apu_nes.wav",1000,180,950)
#test("sweep_apu_famicom.wav",1000,191,955)
#test("sweep_5b_apu.wav",1000,266,947)
#test("sweep_5b_5b.wav",1000,200,951)

plot("sweep_apu_nes.wav","NES APU",1000,180,950,'#FFAA00')
plot("sweep_apu_famicom.wav","Famicom APU",1000,191,955,'#0000FF')
plot("sweep_5b_apu.wav","5B APU",1000,266,947,'#00AA00')
plot("sweep_5b_5b.wav","5B 5B",1000,200,951,'#FF0000')
plot_finish(-45)
