;
; dac_tnd0.s
;   test of APU triangle/noise/DMC nonlinear DAC
;   https://github.com/bbbradsmith/nes-audio-tests
;
; Summary test of APU 2 DAC
;
; 00:00-00:15 - Triangle and DMC
;    Triangle A440
;    DMC triangle simulation volume 15,30,60,120
; 00:15-06:11 - Noise and DMC
;    Noise period $6 volume 1-15
;    DMC noise simulation volume 1-127
; 06:11-11:35 - Square and DMC
;    Square A440 volume 15
;    DMC square simulation volume 1-127
;
; When "silent" triangle is playing at max frequency (ultrasonic).
;
; See misc/dac.py for a program to analyze the output.
;

.include "swap.inc"

NSF_STRINGS "dac_tnd0 test", "Brad Smith", "2019 nes-audio-tests"
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
.import noise_6
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
.word noise_6
.word square_440
DMC_TRIANGLE   = $40 ; arg = 0,1,2,3
DMC_NOISE      = $41 ; arg = 0-127
DMC_NOISE_INIT = $42 ; arg ignored
DMC_SQUARE     = $43 ; arg = 0-127
TRI_MIN        = $44 ; arg ignored
TRI_MAX        = $45 ; arg ignored
TRI_440        = $46 ; arg ignored
TRI_MIN_CYCLE  = $47 ; arg ignored
NOISE_6        = $48 ; arg = 0-15
SQUARE_440     = $49 ; arg = 0-15

test_data:
.byte BUZZ, 50
.byte DELAY, 30
.byte INIT_APU, 0
.byte DMC_NOISE_INIT, 0
.byte TRI_MAX, 0
.byte DELAY, 150
; triangle vs. DMC triangle (4 volumes)
.byte TRI_440, 0
.byte DMC_TRIANGLE, 0
.byte DMC_TRIANGLE, 1
.byte DMC_TRIANGLE, 2
.byte DMC_TRIANGLE, 3
.byte DELAY, 90
; noise vs. DMC noise (15 volumes, 127)
.repeat 15, I
	.byte NOISE_6, (I+1)
.endrepeat
.repeat 127, I
	.byte DMC_NOISE, (I+1)
.endrepeat
.byte DELAY, 90
; APU square (15 only) vs DMC square (127 volumes)
.byte SQUARE_440, 15
.repeat 127, I
	.byte DMC_SQUARE, (I+1)
.endrepeat
.byte DELAY, 90
; finish
.byte LOOP

; end of file
