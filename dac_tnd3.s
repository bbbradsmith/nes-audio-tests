;
; dac_tnd3.s
;   test of APU triangle/noise/DMC nonlinear DAC
;   https://github.com/bbbradsmith/nes-audio-tests
;
; Test of how DMC level affects noise
;
; 00:00-10:08 - DMC at levels 0-15*8
; For each test:
;   DMC level is set  (0.5s)
;   Noise at period $6 volumes 1-15 (each 2s + 0.5s silence)
;
; When "silent" triangle is playing at max frequency (ultrasonic).
;
; See misc/dac.py for a program to analyze the output.
;

.include "swap.inc"

NSF_STRINGS "dac_tnd3 test", "Brad Smith", "2019 nes-audio-tests"
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
.byte INIT_APU, 0
.byte DMC_NOISE_INIT, 0
.byte TRI_MAX, 0
.byte DELAY, 60
.repeat 16, I
	.byte $11, (I*8) ; DMC level
	.byte DELAY, 30
	.repeat 15, J
		.byte NOISE_6, (J+1)
	.endrepeat
.endrepeat
.byte DELAY, 60
.byte LOOP

; end of file
