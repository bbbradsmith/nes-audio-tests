;
; noise_vrc7.s
;   noise spectrum test for VRC7 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "noise_vrc7 test", "Brad Smith", "2018 nes-audio-tests"
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
; APU 56KhZ 1-bit noise
.byte $0C, $3F ; full constant volume
.byte $0E, $03 ; period 3 (32 cycles)
.byte $0F, $FF ; trigger
.byte DELAY, 180
.byte $0C, $10 ; 0 volume
.byte DELAY, 60
; VRC7 noise
.byte REG, $00, $2D ; M: sustain, multiplier x12
.byte REG, $01, $2F ; C: sustain, multiplier x15
.byte REG, $02, $00 ; M: output level 100%
.byte REG, $03, $07 ; C/M: sine, full feedback
.byte REG, $04, $F0 ; M: fast attack, no decay
.byte REG, $05, $F0 ; C: fast attack, no decay
.byte REG, $06, $0F ; M: full sustain, fast release
.byte REG, $07, $0F ; M: full sustain, fast release
.byte REG, $30, $00 ; custom instrument, full volume
.byte REG, $10, <290 ; ~440Hz (doesn't matter)
.byte REG, $20, (290>>8) | (4<<1) | (1<<4) ; ~440Hz, octave 4, trigger note
.byte DELAY, 180
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
