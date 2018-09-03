;
; lfo_vrc7.s
;   LFO reset test for VRC7 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "lfo_vrc7 test", "Brad Smith", "2018 nes-audio-tests"
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
.word lfo_reset
INIT_VRC7 = $40 ; arg ignored
REG       = $41 ; two byte arg: register, value
LFO_RESET = $42 ; LFO reset?

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_VRC7, 0
.byte DELAY, 60
; VRC7 440Hz, instrument 11
.byte LFO_RESET, $00
.byte REG, $30, $B0 ; instrument 11, full volume
.byte REG, $10, <290 ; ~440Hz
.byte REG, $20, (290>>8) | (4<<1) | (1<<4) ; ~440Hz, octave 4, trigger note
.byte DELAY, 120
.byte REG, $20, $00 ; release note
.byte DELAY, 60
.byte LFO_RESET, $00
.byte REG, $30, $B0 ; instrument 11, full volume
.byte REG, $10, <290 ; ~440Hz
.byte REG, $20, (290>>8) | (4<<1) | (1<<4) ; ~440Hz, octave 4, trigger note
.byte DELAY, 120
.byte REG, $20, $00 ; release note
.byte DELAY, 71
.byte LFO_RESET, $00
.byte REG, $30, $B0 ; instrument 11, full volume
.byte REG, $10, <290 ; ~440Hz
.byte REG, $20, (290>>8) | (4<<1) | (1<<4) ; ~440Hz, octave 4, trigger note
.byte DELAY, 120
.byte REG, $20, $00 ; release note
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

lfo_reset:
	lda #$40
	sta $E000
	jsr swap_delay_frame
	lda #$00
	sta $E000
	jsr swap_delay_frame
	rts

; end of file
