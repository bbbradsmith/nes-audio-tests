;
; db_5b.s
;   relative volume test for 5B expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.define NSF_TITLE      "db_5b test"
.define NSF_ARTIST     "Brad Smith"
.define NSF_COPYRIGHT  "2018 nes-audio-tests"
NSF_EXPANSION = %00100000

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION

.include "swap.inc"

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

.segment "NSF_HEADER1"
.byte NSF_TITLE
.res 32 - .strlen(NSF_TITLE)
.byte NSF_ARTIST
.res 32 - .strlen(NSF_ARTIST)
.byte NSF_COPYRIGHT
.res 32 - .strlen(NSF_COPYRIGHT)
.assert * = $6E, error, "NSF strings may be too long?"

; end of file
