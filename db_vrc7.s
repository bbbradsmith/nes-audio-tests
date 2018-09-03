;
; db_vrc7.s
;   relative volume test for VRC7 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_vrc7 test", "Brad Smith", "2018 nes-audio-tests"
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
; APU 440Hz square
.byte $00, %10111111 ; square duty, constant, full volume
.byte $02, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte $03, $F0
.byte DELAY, 120
.byte $00, %00110000 ; zero volume
.byte DELAY, 60
; VRC7 440Hz "square"
.byte REG, $00, $22 ; M: sustain, multiplier x2
.byte REG, $01, $21 ; C: sustain, multiplier x1
.byte REG, $02, $20 ; M: output level 50%
.byte REG, $03, $07 ; C/M: sine, full feedback
.byte REG, $04, $F0 ; M: fast attack, no decay
.byte REG, $05, $F0 ; C: fast attack, no decay
.byte REG, $06, $0F ; M: full sustain, fast release
.byte REG, $07, $0F ; M: full sustain, fast release
.byte REG, $30, $00 ; custom instrument, full volume
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
	ldx #$40
	stx $E000 ; disable audio (resets LFO)
	jsr wait_9030
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
