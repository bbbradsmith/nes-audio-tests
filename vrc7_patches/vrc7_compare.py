#!/usr/bin/env python3
import sys
assert sys.version_info[0] >= 3, "Python 3 required."

file_a = "rainwarrior_1.vrc7"
file_b = "rainwarrior_2.vrc7"

PARAM = [
    "M tremolo",
    "M vibrato",
    "M hold sustain",
    "M key rate scale",
    "M multiplier",
    "C tremolo",
    "C vibrato",
    "C hold sustain",
    "C key rate scale",
    "C multiplier",
    "M key level scale",
    "M output",
    "C key level scale",
    "C waveform",
    "M waveform",
    "feedback",
    "M attack",
    "M decay",
    "C attack",
    "C decay",
    "M sustain",
    "M release",
    "C sustain",
    "C release" ]

def patch_split(p):
    mt = (p[0] >> 7) & 1  # M tremolo
    mv = (p[0] >> 6) & 1  # M vibrato
    mh = (p[0] >> 5) & 1  # M sustain (hold)
    mk = (p[0] >> 4) & 1  # M key rate scale
    mm = (p[0] >> 0) & 15 # M mult
    ct = (p[1] >> 7) & 1  # C tremolo
    cv = (p[1] >> 6) & 1  # C vibrato
    ch = (p[1] >> 5) & 1  # C sustain (hold)
    ck = (p[1] >> 4) & 1  # C key rate scale
    cm = (p[1] >> 0) & 15 # C mult
    ml = (p[2] >> 6) & 3  # M key level scale
    mo = (p[2] >> 0) & 63 # M output
    cl = (p[3] >> 6) & 3  # C key level scale
    cw = (p[3] >> 4) & 1  # C waveform
    mw = (p[3] >> 3) & 1  # M waveform
    fb = (p[3] >> 0) & 7  # feedback
    ma = (p[4] >> 4) & 15 # M attack
    md = (p[4] >> 0) & 15 # M decay
    ca = (p[5] >> 4) & 15 # C attack
    cd = (p[5] >> 0) & 15 # C decay
    ms = (p[6] >> 4) & 15 # M sustain
    mr = (p[6] >> 0) & 15 # M release
    cs = (p[7] >> 4) & 15 # M sustain
    cr = (p[7] >> 0) & 15 # M release
    return [mt,mv,mh,mk,mm,ct,cv,ch,ck,cm,ml,mo,cl,cw,mw,fb,ma,md,ca,cd,ms,mr,cs,cr]

def patch_dump(p):
    ps = patch_split(p)
    for i in range(len(ps)):
        print("%2d %s" % (ps[i], PARAM[i]))

def patch_compare(pa,pb):
    psa = patch_split(pa)
    psb = patch_split(pb)
    for i in range(len(psa)):
        if psa[i] != psb[i]:
            print("%2d %2d %s" % (psa[i], psb[i], PARAM[i]))

def file_dump(f):
    print(f)
    print()
    r = open(f,"rb").read()
    for i in range(1,16):
        p = r[8*i:8*i+8]
        print("Patch %d" % i)
        patch_dump(p)
        print()
    print()
    print()    

def file_compare(fa,fb):
    ra = open(fa,"rb").read()
    rb = open(fb,"rb").read()
    print("A: " + fa)
    print("B: " + fb)
    print()
    for i in range(1,16):
        pa = ra[8*i:8*i+8]
        pb = rb[8*i:8*i+8]
        print("Patch %d" % i)
        patch_compare(pa,pb)
        print()
    print()
    print()    

#file_dump(file_a)
#file_dump(file_b)
file_compare(file_a, file_b)
