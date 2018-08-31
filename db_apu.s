;
; db_apu.s
;   relative volume test for APU triangle
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_apu test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00000000
SKIP_HOTSWAP = 1

.export test_registers
.export test_routines
.export test_data
.exportzp SKIP_HOTSWAP
.exportzp NSF_EXPANSION

.segment "SWAP"

test_registers: ; $20
; not used

test_routines: ; $40
; not used

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte DELAY, 60
; APU 440Hz square
.byte $00, %10111111 ; square duty, constant, full volume
.byte $02, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte $03, $F0 ; begin
.byte DELAY, 120
.byte $00, %00110000 ; zero volume
.byte DELAY, 60
; APU 440Hz triangle
.byte $08, $FF ; halt counter
.byte $0A, 126 ; (126+1)*32 = 4064 cycle triangle = ~440.40Hz
.byte $0B, $F0 ; begin
.byte DELAY, 120
.byte $08, $80 ; silence
.byte DELAY, 60
.byte LOOP

; end of file
