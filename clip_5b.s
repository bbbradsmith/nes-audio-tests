;
; clip_5b.s
;   amplifier clipping test for 5B expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "clip_5b test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00100000
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "SWAP"

test_registers: ; $20
; not used

test_routines: ; $40
.word init_5b
.word reg
INIT_5B = $40 ; arg ignored
REG     = $41 ; two byte arg: register, value

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_5B, 0
.byte DELAY, 60
; 5B 220Hz square
.byte DELAY, 10
.byte REG, $0, <508
.byte REG, $1, >508
.byte REG, $2, 254
.byte REG, $4, 127
.byte REG, $7, %00111000
.byte REG, $8, $09, DELAY, 60
.byte REG, $9, $09, DELAY, 60
.byte REG, $A, $09, DELAY, 60
.byte REG, $8, $00, REG, $9, $00, REG, $A, $00, DELAY, 60
.byte DELAY, 60
.byte REG, $8, $0A, DELAY, 60
.byte REG, $9, $0A, DELAY, 60
.byte REG, $A, $0A, DELAY, 60
.byte REG, $8, $00, REG, $9, $00, REG, $A, $00, DELAY, 60
.byte DELAY, 60
.byte REG, $8, $0B, DELAY, 60
.byte REG, $9, $0B, DELAY, 60
.byte REG, $A, $0B, DELAY, 60
.byte REG, $8, $00, REG, $9, $00, REG, $A, $00, DELAY, 60
.byte DELAY, 60
.byte REG, $8, $0C, DELAY, 60
.byte REG, $9, $0C, DELAY, 60
.byte REG, $A, $0C, DELAY, 60
.byte REG, $8, $00, REG, $9, $00, REG, $A, $00, DELAY, 60
.byte DELAY, 60
.byte REG, $8, $01, DELAY, 10
.byte REG, $8, $02, DELAY, 10
.byte REG, $8, $03, DELAY, 10
.byte REG, $8, $04, DELAY, 10
.byte REG, $8, $05, DELAY, 10
.byte REG, $8, $06, DELAY, 10
.byte REG, $8, $07, DELAY, 10
.byte REG, $8, $08, DELAY, 10
.byte REG, $8, $09, DELAY, 10
.byte REG, $8, $0A, DELAY, 10
.byte REG, $8, $0B, DELAY, 10
.byte REG, $8, $0C, DELAY, 10
.byte REG, $8, $0D, DELAY, 10
.byte REG, $8, $0E, DELAY, 10
.byte REG, $8, $0F, DELAY, 60
.byte REG, $9, $01, DELAY, 10
.byte REG, $9, $02, DELAY, 10
.byte REG, $9, $03, DELAY, 10
.byte REG, $9, $04, DELAY, 10
.byte REG, $9, $05, DELAY, 10
.byte REG, $9, $06, DELAY, 10
.byte REG, $9, $07, DELAY, 10
.byte REG, $9, $08, DELAY, 10
.byte REG, $9, $09, DELAY, 10
.byte REG, $9, $0A, DELAY, 10
.byte REG, $9, $0B, DELAY, 10
.byte REG, $9, $0C, DELAY, 10
.byte REG, $9, $0D, DELAY, 10
.byte REG, $9, $0E, DELAY, 10
.byte REG, $9, $0F, DELAY, 60
.byte REG, $A, $01, DELAY, 10
.byte REG, $A, $02, DELAY, 10
.byte REG, $A, $03, DELAY, 10
.byte REG, $A, $04, DELAY, 10
.byte REG, $A, $05, DELAY, 10
.byte REG, $A, $06, DELAY, 10
.byte REG, $A, $07, DELAY, 10
.byte REG, $A, $08, DELAY, 10
.byte REG, $A, $09, DELAY, 10
.byte REG, $A, $0A, DELAY, 10
.byte REG, $A, $0B, DELAY, 10
.byte REG, $A, $0C, DELAY, 10
.byte REG, $A, $0D, DELAY, 10
.byte REG, $A, $0E, DELAY, 10
.byte REG, $A, $0F, DELAY, 120
; APU triangle
.byte $08, $FF ; halt counter
.byte $0A, 118 ; 470Hz
.byte $0B, $F0 ; begin APU triangle
.BYTE DELAY, 120
.byte REG, $7, %00111111 ; disable 5B
.byte DELAY, 60
.byte $08, $80 ; silence triangle
.byte DELAY, 60
.byte LOOP

reg:
	tya
	tax ; X = register
	ldy #0
	lda (read_ptr), Y
	tay ; Y = value
	inc read_ptr+0
	bne :+
		inc read_ptr+1
	:
	stx $C000
	sty $E000
	rts

init_5b:
	ldy #0
	ldx #0
	: ; 0 to all registers
		stx $C000
		sty $E000
		inx
		cpx #$10
		bcc :-
	lda #$07 ; disable all noise/tone
	sta $C000
	lda #%00111111
	sta $E000
	rts

; end of file
