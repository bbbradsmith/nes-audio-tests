#
# Was used to analyze sweep_5b results.
#

#
# 1. Record sweep_5b
# 2. Trim a WAV to the start and end of the sweep portion of the recording.
# 3. Run test() on the WAV to create a frequency graph.
# 4. Use the graph to set the trim points to
#  the start and end of the consistent linear part of the graph.
# 5. Use plot() with the chosen trim points to create the finished response graph.
#
# plot_reload() and be used to re-plot cached graphs
# plot_array() can be used to graph some filter models (see below)
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

def v_to_db(v):
    return 20*math.log10(v)

def db_to_v(db):
    return pow(10,db/20)

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
    pyplot.ylim(dbr,3)
    global legends
    if len(legends) > 0:
        pyplot.legend(legends,loc='lower right')
    pyplot.show()
    legends = []

def plot(filename,name=None,points=1000,trim0=0,trim1=-1,color='#000000',alpha=0.75,thickness=5,scatter=True):
    global legends
    print("plot(%s)" % filename)
    if trim1 < 0:
        trim1 = points
    w = loadwave(filename)
    a = sweepalyze(w,points)
    linf = [x[1] for x in a]
    logm = [v_to_db(x[2]) for x in a]
    linf = linf[trim0:trim1]
    db = normaldb(logm[trim0:trim1])
    if scatter:
        pyplot.scatter(linf,db,s=thickness,c=color,alpha=alpha)
    else:
        pyplot.plot(linf,db,linewidth=thickenss,c=color,alpha=alpha)
    if name == None:
        name = filename
    legends.append(name)
    filearray = filename + ".array"
    numpy.savetxt(filearray, list(zip(linf,db)))
    print("saved: %s.array" % filename)

def plot_array(a,name,color='#000000',alpha=0.75,thickness=5,scatter=True):
    global legends
    print("plot_array(%s)" % name)
    (linf, db) = zip(*a)
    if scatter:
        pyplot.scatter(linf,db,s=thickness,c=color,alpha=alpha)
    else:
        pyplot.plot(linf,db,linewidth=thickness,c=color,alpha=alpha)
    legends.append(name)

def plot_reload(filename,name,points=1000,trim0=0,trim1=-1,color='#000000',alpha=0.75,thickness=5,scatter=True):
    try:
        a = numpy.loadtxt(filename + ".array")
        plot_array(a,name,color,alpha,thickness,scatter)
    except:
        plot(filename,name,points,trim0,trim1,color,alpha,thickness,scatter)

def test(filename,points=1000,trim0=0,trim1=-1):
    if trim1 < 0:
        trim1 = points
    w = loadwave(filename)
    a = sweepalyze(w,points)
    linf = [x[1] for x in a]
    logf = [math.log(x[1]) for x in a]
    logm = [v_to_db(x[2]) for x in a]
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
#test("sweep_5b_recap_apu.wav",1000,226,950)
#test("sweep_5b_recap_5b.wav",1000,180,945)

#plot("sweep_apu_nes.wav","NES APU",1000,180,950,'#FFAA00')
#plot("sweep_apu_famicom.wav","Famicom APU",1000,191,955,'#0000FF')
#plot("sweep_5b_apu.wav","5B APU",1000,266,947,'#00AA00')
#plot("sweep_5b_5b.wav","5B 5B",1000,200,951,'#FF0000')
#plot("sweep_5b_recap_apu.wav",'5B APU Recap',1000,226,950,'#00FF88')
#plot("sweep_5b_recap_5b.wav",'5B 5B Recap',1000,180,945,'#AA00FF')
#plot_finish(-45)

# Comparison of some Famicom APUs
#plot("sweep_apu_famicom.wav","rainwarrior Modded Famicom",1000,191,955,'#0000FF')
#plot("sweep_5b_jamesf_av.wav","James-F AV Famicom",1000,195,955,'#00AA00')
#plot("sweep_5b_jamesf_modded.wav","James-F Modded HVC-CPU-07",1000,178,955,'#FF0000')
#plot_reload("sweep_apu_famicom.wav","1. rainwarrior Modded Famicom",'#0000FF',0.5,10)
#plot_reload("sweep_5b_jamesf_av.wav","2. James-F AV Famicom",'#00AA00',0.5,10)
#plot_reload("sweep_5b_jamesf_modded.wav","3. James-F Modded HVC-CPU-07",'#FF0000',0.5,10)
#plot_finish(-45)

def model_reload(filename):
    a = numpy.loadtxt(filename + ".array")
    return [(f,db_to_v(db)) for (f,db) in a]

def model_base(start,stop,steps):
    a = math.log(start)
    b = math.log(stop)
    return [(math.exp(a+(b-a)*(x/(steps-1))),1) for x in range(0,steps)]

def model_hp1(cutoff,start=0.5,stop=6000,steps=1000):
    a = model_base(start,stop,steps)
    a = model_filter_highpass(a,cutoff)
    return model_db(a)

def model_hp2(cutoff0,cutoff1,start=0.5,stop=6000,steps=1000):
    a = model_base(start,stop,steps)
    a = model_filter_highpass(a,cutoff0)
    a = model_filter_highpass(a,cutoff1)
    return model_db(a)

def model_db(a):
    (f,v) = zip(*a)
    db = list(map(v_to_db, v))
    return zip(f, normaldb(db))

def model_filter_highpass(a,cutoff):
    if (cutoff <= 0):
        return a
    return [(f,
         v * (f/cutoff) / math.sqrt(1+(f/cutoff)**2)
        ) for (f,v) in a]

def model_unfilter_highpass(a,cutoff):
    if (cutoff <= 0):
        return a
    return [(f,
         v * math.sqrt(1+(f/cutoff)**2) / (f/cutoff)
        ) for (f,v) in a]

hp_ftp =  3.0 # recording device
hp_nes = 16.0 # NES APU highpass
hp_fc  = 32.0 # famicom APU highpass
hp_5b0 = 20.0 # 5B 5B input highpass
hp_5b1=  12.0 # 5B APU input highpass
hp_5b2 = 12.0 # 5B output highpass

def model_apu_nes(start=0.5,stop=6000,steps=1000):
    a = model_base(start,stop,steps)
    a = model_filter_highpass(a,hp_nes)
    a = model_filter_highpass(a,hp_ftp)
    return model_db(a)

def model_apu_famicom(start=0.5,stop=6000,steps=1000):
    a = model_base(start,stop,steps)
    a = model_filter_highpass(a,hp_fc)
    a = model_filter_highpass(a,hp_ftp)
    return model_db(a)

def model_5b_apu(start=0.5,stop=6000,steps=1000):
    a = model_base(start,stop,steps)
    a = model_filter_highpass(a,hp_fc)
    a = model_filter_highpass(a,hp_5b1)
    a = model_filter_highpass(a,hp_5b2)
    a = model_filter_highpass(a,hp_ftp)
    return model_db(a)

def model_5b_5b(start=0.5,stop=6000,steps=1000):
    a = model_base(start,stop,steps)
    a = model_filter_highpass(a,hp_5b0)
    a = model_filter_highpass(a,hp_5b2)
    a = model_filter_highpass(a,hp_ftp)
    return model_db(a)

def model_test(filename,ca,cb,cc):
    a = model_reload(filename)
    a = model_unfilter_highpass(a,ca)
    a = model_unfilter_highpass(a,cb)
    a = model_unfilter_highpass(a,cc)
    return model_db(a)

def redo():
    plot_array(model_apu_nes(),"NES APU Model (%.1fHz)"%hp_nes,"#FFAA00",1,1,False)
    plot_array(model_apu_famicom(),"Famicom APU Model (%.1fHz)"%hp_fc,"#0000FF",1,1,False)
    plot_array(model_5b_apu(),"5B APU Model (%.1fHz, %.1fHz, %.1fHz)"%(hp_fc,hp_5b1,hp_5b2),'#00AA00',1,1,False)
    plot_array(model_5b_5b(),"5B 5B Model (%.1fHz, %.1fHz)"%(hp_5b0,hp_5b2),'#FF0000',1,1,False)
    #plot_array(model_hp1(19),"test_2",'#00FFFF',1,1,False)
    plot_reload("sweep_apu_nes.wav","NES APU",1000,180,950,'#FFAA00',0.1,10)
    plot_reload("sweep_apu_famicom.wav","Famicom APU",1000,191,955,'#0000FF',0.1,10)
    plot_reload("sweep_5b_apu.wav","5B APU",1000,266,947,'#00AA00',0.1,10)
    plot_reload("sweep_5b_5b.wav","5B 5B",1000,200,951,'#FF0000',0.1,10)
    #plot_array(model_test("sweep_5b_apu.wav",hp_fc,hp_ftp,13),"test",'#FF00FF',1,1,True)
    #plot_finish(-21)
    plot_finish(-39)
redo()

def r(a=None,b=None,c=None):
    if a != None:
        global hp_5b0
        hp_5b0 = a
    if b != None:
        global hp_5b1
        hp_5b1 = b
    if c != None:
        global hp_5b2
        hp_5b2 = c
    redo()
