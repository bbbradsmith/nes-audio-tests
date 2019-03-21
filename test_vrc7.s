;
; test_vrc7.s
;   Test of VRC7 test register $0F
;     3 second reference tone
;     8 x 3 second tones setting a bit from the test register
;       1 second normal after key on
;       1 second with test register bit set
;       1 second after test register bit cleared
;       1 second key off and wait
;     3 x 1 second tones with $0F bit 1 set and clear before each (LFO reset)
;     3 x 1 second tones without $0F usage (LFO free-run)
;   Test repeats twice with instrument 10 (110Hz) and instrument 12 (440Hz)
;
;   Information here: https://forums.nesdev.com/viewtopic.php?p=236371#p236371
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "test_vrc7 test", "Brad Smith", "2019 nes-audio-tests"
NSF_EXPANSION = %00000010
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "ZEROPAGE"
temp:            .res 1
tone_instrument: .res 1
tone_low:        .res 1
tone_high:       .res 1
tone_octave:     .res 1

.segment "SWAP"

test_registers: ; $20
; not used

test_routines: ; $40
.word init_vrc7
.word reg
.word tone_play ; arg = 1 play tone, arg = 0 stop tone
.word tone_inst
.word tone_freq
.word tone_oct
INIT_VRC7 = $40 ; arg ignored
REG       = $41 ; two byte arg: register, value
TONE_PLAY = $42 ; arg = 0 stop tone, else play
TONE_INST = $43 ; instrument
TONE_FREQ = $44 ; two byte arg: 9 bit frequency register value
TONE_OCT  = $45 ; octave

; 440Hz
TONE_F = 290
TONE_O = 4

test_data:

; setup
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_VRC7, 0

; instrument 10, 110Hz
.byte TONE_INST, 10
.byte TONE_FREQ, <290, >290
.byte TONE_OCT, 2

.byte DELAY, 60

; reference 3-second tone
.byte TONE_PLAY, 1
.byte DELAY, 180
.byte TONE_PLAY, 0
.byte DELAY, 60

; 8 3-second tones each with a different test bit set during the middle second
.repeat 8, I
.byte TONE_PLAY, 1
.byte DELAY, 60
.byte REG, $F, (1 << I)
.byte DELAY, 60
.byte REG, $F, $00
.byte DELAY, 60
.byte TONE_PLAY, 0
.byte DELAY, 60
.endrepeat

; 3 tones with LFO reset?
.repeat 3, I
.byte REG, $F, 2
.byte REG, $F, 0
.byte TONE_PLAY, 1
.byte DELAY, 60
.byte TONE_PLAY, 0
.byte DELAY, 60
.endrepeat

; 3 tones, free run LFO
.repeat 3, I
.byte TONE_PLAY, 1
.byte DELAY, 60
.byte TONE_PLAY, 0
.byte DELAY, 60
.endrepeat

; instrument 12, 440Hz
.byte TONE_INST, 12
.byte TONE_FREQ, <290, >290
.byte TONE_OCT, 4

.byte DELAY, 60

.byte TONE_PLAY, 1
.byte DELAY, 180
.byte TONE_PLAY, 0
.byte DELAY, 60

.repeat 8, I
.byte TONE_PLAY, 1
.byte DELAY, 60
.byte REG, $F, (1 << I)
.byte DELAY, 60
.byte REG, $F, $00
.byte DELAY, 60
.byte TONE_PLAY, 0
.byte DELAY, 60
.endrepeat

.repeat 3, I
.byte REG, $F, 2
.byte REG, $F, 0
.byte TONE_PLAY, 1
.byte DELAY, 60
.byte TONE_PLAY, 0
.byte DELAY, 60
.endrepeat

.repeat 3, I
.byte TONE_PLAY, 1
.byte DELAY, 60
.byte TONE_PLAY, 0
.byte DELAY, 60
.endrepeat

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

tone_inst:
	tya
	asl
	asl
	asl
	asl
	sta tone_instrument
	rts

tone_freq:
	sty tone_low
	ldy #0
	lda (read_ptr), Y
	tay
	inc read_ptr+0
	bne :+
		inc read_ptr+1
	:
	tya
	and #1
	sta tone_high
	rts

tone_oct:
	tya
	and #7
	asl
	sta tone_octave
	rts

tone_play:
	cpy #0
	beq tone_stop
	ldy tone_instrument
	ldx #$30
	jsr reg_write
	ldy tone_low
	ldx #$10
	jsr reg_write
	lda tone_high
	ora tone_octave
	ora #$10
	tay
	ldx #$20
	jsr reg_write
	rts
tone_stop:
	lda tone_high
	ora tone_octave
	tay
	ldx #$20
	jsr reg_write
	rts

; end of file
