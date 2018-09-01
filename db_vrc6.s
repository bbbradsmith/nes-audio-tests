;
; db_vrc6.s
;   relative volume test for VRC6 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_vrc6 test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00000001
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "SWAP"

.import VRC6A
test_registers: ; $20
.word $9000
.word $9001 + (1 - VRC6A)
.word $9002 + (VRC6A - 1)
.word $9003
.word $A000
.word $A001 + (1 - VRC6A)
.word $A002 + (VRC6A - 1)
.word $A003
.word $B000
.word $B001 + (1 - VRC6A)
.word $B002 + (VRC6A - 1)
.word $B003
V9000 = $20
V9001 = $21
V9002 = $22
V9003 = $23
VA000 = $24
VA001 = $25
VA002 = $26
VA003 = $27
VB000 = $28
VB001 = $29
VB002 = $2A
VB003 = $2B

test_routines: ; $40
.word init_vrc6
INIT_VRC6 = $40 ; arg ignored

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_VRC6, 0
.byte DELAY, 60
; APU 440Hz square
.byte $00, %10111111 ; square duty, constant, full volume
.byte $02, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte $03, $F0
.byte DELAY, 120
.byte $00, %00110000 ; zero volume
.byte DELAY, 60
; vrc6 440Hz square
.byte V9000, $7F ; square duty, full volume
.byte V9001, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte V9002, $80
.byte DELAY, 120
.byte V9002, $00
.byte DELAY, 60
.byte LOOP

init_vrc6:
	ldy #0
	sty $9003
	sty $9002
	sty $9001
	sty $9000
	sty $A002
	sty $A001
	sty $A000
	sty $B002
	sty $B001
	sty $B000
	rts

; end of file
