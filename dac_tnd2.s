;
; dac_tnd2.s
;   test of APU triangle/noise/DMC nonlinear DAC
;   https://github.com/bbbradsmith/nes-audio-tests
;
; Test of how triangle level affects noise and DMC
;
; 00:00-09:09
;
; For each test (repeated 33 times):
;   Triangle is unhalted for ~1s + 1 waveform step
;   Noise at period $B volumes 1, 8, 15
;   DMC simulated noise volumes 8, 64, 120
;
; Though the starting phase of the triangle will be unknown,
; this test will cycle through all 32 positions of its waveform
; to test the noise/DMC levels against.
;
; See misc/dac_tnd.py for a program to analyze the output.
;

.include "swap.inc"

NSF_STRINGS "dac_tnd2 test", "Brad Smith", "2019 nes-audio-tests"
NSF_EXPANSION = %00000000

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION

.segment "SHARED"

test_registers: ; $20
; not used

.import dmc_triangle
.import dmc_noise
.import dmc_noise_init
.import dmc_square
.import tri_min
.import tri_max
.import tri_440
.import tri_min_cycle
.import noise_b
.import square_440

test_routines: ; $40
.word dmc_triangle
.word dmc_noise
.word dmc_noise_init
.word dmc_square
.word tri_min
.word tri_max
.word tri_440
.word tri_min_cycle
.word noise_b
.word square_440
DMC_TRIANGLE   = $40 ; arg = 0,1,2,3
DMC_NOISE      = $41 ; arg = 0-127
DMC_NOISE_INIT = $42 ; arg ignored
DMC_SQUARE     = $43 ; arg = 0-127
TRI_MIN        = $44 ; arg ignored
TRI_MAX        = $45 ; arg ignored
TRI_440        = $46 ; arg ignored
TRI_MIN_CYCLE  = $47 ; arg ignored
NOISE_B        = $48 ; arg = 0-15
SQUARE_440     = $49 ; arg = 0-15

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte DMC_NOISE_INIT, 0
.byte TRI_MIN, 0
.byte $15, %00001011 ; silence triangle at min frequency
.byte DELAY, 60
.repeat 33
	.byte TRI_MIN_CYCLE, 0
	.byte DELAY, 30
	.byte NOISE_B, 1
	.byte NOISE_B, 8
	.byte NOISE_B, 15
	.byte DMC_NOISE, 8
	.byte DMC_NOISE, 64
	.byte DMC_NOISE, 120
.endrepeat
.byte DELAY, 60
.byte LOOP

; end of file
