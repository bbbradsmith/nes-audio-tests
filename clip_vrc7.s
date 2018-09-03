;
; clip_vrc7.s
;   amplifier clipping test for VRC7 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "clip_vrc7 test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00000010
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "ZEROPAGE"
temp: .res 1

.segment "SWAP"

test_registers: ; $20
; not used

test_routines: ; $40
.word init_vrc7
.word reg
INIT_VRC7 = $40 ; arg ignored
REG       = $41 ; two byte arg: register, value

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_VRC7, 0
.byte DELAY, 60
; VRC7 plain sine
.byte REG, $00, $01 ; M: multiplier x1
.byte REG, $01, $21 ; C: sustain, multiplier x1
.byte REG, $02, $3F ; M: output level minimum
.byte REG, $03, $00 ; C/M: sine, no feedback
.byte REG, $04, $F0 ; M: fast attack, no decay
.byte REG, $05, $F0 ; C: fast attack, no decay
.byte REG, $06, $0F ; M: full sustain, fast release
.byte REG, $07, $0F ; M: full sustain, fast release
.byte REG, $30, $00 ; custom instrument, full volume
TONE0 = <290 ; ~220Hz
TONE1 = (290>>8) | (3<<1) | (1<<4) ; ~220Hz, octave 3, trigger note
.byte REG, $10, TONE0
.byte REG, $11, TONE0
.byte REG, $12, TONE0
.byte REG, $13, TONE0
.byte REG, $14, TONE0
.byte REG, $15, TONE0
.byte REG, $20, TONE1
.byte DELAY, 20
.byte REG, $20, $00 ; release note
.byte DELAY, 10
.byte REG, $20, TONE1
.byte REG, $21, TONE1
.byte DELAY, 20
.byte REG, $20, $00
.byte REG, $21, $00
.byte DELAY, 10
.byte REG, $20, TONE1
.byte REG, $21, TONE1
.byte REG, $22, TONE1
.byte DELAY, 20
.byte REG, $20, $00
.byte REG, $21, $00
.byte REG, $22, $00
.byte DELAY, 10
.byte REG, $20, TONE1
.byte REG, $21, TONE1
.byte REG, $22, TONE1
.byte REG, $23, TONE1
.byte DELAY, 20
.byte REG, $20, $00
.byte REG, $21, $00
.byte REG, $22, $00
.byte REG, $23, $00
.byte DELAY, 10
.byte REG, $20, TONE1
.byte REG, $21, TONE1
.byte REG, $22, TONE1
.byte REG, $23, TONE1
.byte REG, $24, TONE1
.byte DELAY, 20
.byte REG, $20, $00
.byte REG, $21, $00
.byte REG, $22, $00
.byte REG, $23, $00
.byte REG, $24, $00
.byte DELAY, 10
.byte REG, $20, TONE1
.byte REG, $21, TONE1
.byte REG, $22, TONE1
.byte REG, $23, TONE1
.byte REG, $24, TONE1
.byte REG, $25, TONE1
.byte DELAY, 20
.byte REG, $20, $00
.byte REG, $21, $00
.byte REG, $22, $00
.byte REG, $23, $00
.byte REG, $24, $00
.byte REG, $25, $00
.byte DELAY, 60
; all channels sine + APU triangle
.byte $08, $FF ; halt counter
.byte $0A, 118 ; 470Hz
.byte $0B, $F0 ; begin APU triangle
.byte DELAY, 60
.byte REG, $20, TONE1
.byte REG, $21, TONE1
.byte REG, $22, TONE1
.byte REG, $23, TONE1
.byte REG, $24, TONE1
.byte REG, $25, TONE1
.byte DELAY, 120
.byte REG, $20, $00
.byte REG, $21, $00
.byte REG, $22, $00
.byte REG, $23, $00
.byte REG, $24, $00
.byte REG, $25, $00
.byte DELAY, 60
.byte $08, $80 ; silence triangle
.byte DELAY, 60
.byte LOOP

; register write delay code from Lagrange Point
wait_9030:
    stx temp
    ldx #$08
@wait_loop:
    dex
    bne @wait_loop
    ldx temp
wait_9010:
    rts

reg_write: ; X = register, Y = value
	stx $9010
	jsr wait_9010
	sty $9030
	jmp wait_9030

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
	jmp reg_write

init_vrc7:
	ldy #0
	ldx #0
	stx $E000 ; enable audio
	: ; 0 to all registers
		jsr reg_write
		inx
		cpx #$40
		bcc :-
	rts

; end of file
