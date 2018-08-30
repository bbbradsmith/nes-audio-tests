;
; db_5b.s
;   relative volume test for 5B expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_5b test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00100000
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "SWAP"

test_registers: ; $20
.word $C000
.word $E000
SELECT = $20
WRITE  = $21

test_routines: ; $40
.word init_5b
INIT_5B = $40

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_5B, 0
.byte DELAY, 60
; TODO
.byte LOOP

init_5b:
	ldy #0
	ldx #0
	:
		stx $C000
		sty $E000
		inx
		cpx #$10
		bcc :-
	rts

; end of file
