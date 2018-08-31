;
; db_mmc5.s
;   relative volume test for MMC5 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_mmc5 test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00001000
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "SWAP"

test_registers: ; $20
.word $5000
.word $5001
.word $5002
.word $5003
.word $5004
.word $5005
.word $5006
.word $5007
.word $5010
.word $5011
.word $5015
V5000 = $20
V5001 = $21
V5002 = $22
V5003 = $23
V5004 = $24
V5005 = $25
V5006 = $26
V5007 = $27
V5010 = $28
V5011 = $29
V5015 = $2A

test_routines: ; $40
.word init_mmc5
INIT_MMC5 = $40 ; arg ignored

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_MMC5, 0
.byte DELAY, 60
; APU 440Hz square
.byte $00, %10111111 ; square duty, constant, full volume
.byte $02, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte $03, $F0
.byte DELAY, 120
.byte $00, %00110000 ; zero volume
.byte DELAY, 60
; MMC5 440Hz square
.byte V5000, %10111111 ; square duty, constant, full volume
.byte V5002, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte V5003, $F0
.byte DELAY, 120
.byte V5000, %00110000 ; zero volume
.byte DELAY, 60
.byte LOOP

init_mmc5:
	lda #0
	ldx #0
	:
		sta $5000, X
		inx
		cpx #$16
		bcc :-
	lda #%00000011
	sta $5015
	rts

; end of file
