;
; dac_tnd1.s
;   test of APU triangle/noise/DMC nonlinear DAC
;   https://github.com/bbbradsmith/nes-audio-tests
;

;
; TODO description
;
; See misc/dac_tnd.py for a program to analyze the output.
;

.include "swap.inc"

NSF_STRINGS "dac_tnd1 test", "Brad Smith", "2019 nes-audio-tests"
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
DMC_TRIANGLE   = $40 ; arg = 0,1,2,3
DMC_NOISE      = $41 ; arg = 0-127
DMC_NOISE_INIT = $42 ; arg ignored
DMC_SQUARE     = $43 ; arg = 0-127
TRI_MIN        = $44 ; arg ignored
TRI_MAX        = $45 ; arg ignored
TRI_440        = $46 ; arg ignored
TRI_MIN_CYCLE  = $47 ; arg ignored
NOISE_B        = $48 ; arg = 0-15

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte DELAY, 60
; TODO
.byte DELAY, 60
.byte LOOP

; end of file
