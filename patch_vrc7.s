;
; patch_vrc7.s
;   patch test for VRC7 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "patch_vrc7 test", "Brad Smith", "2019 nes-audio-tests"
NSF_EXPANSION = %00000010
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "ZEROPAGE"
inst: .res 1
tone0: .res 1
tone1: .res 1
temp: .res 1

.segment "SWAP"

patch_set:
.incbin "vrc7_patches/nukeykt.vrc7"

test_registers: ; $20
; not used

test_routines: ; $40
.word init_vrc7
.word reg
.word patch
INIT_VRC7 = $40 ; arg ignored
REG       = $41 ; two byte arg: register, value
PATCH     = $42 ; patch test for arg

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_VRC7, 0
.byte DELAY, 60
.byte PATCH, 1
.byte PATCH, 2
.byte PATCH, 3
.byte PATCH, 4
.byte PATCH, 5
.byte PATCH, 6
.byte PATCH, 7
.byte PATCH, 8
.byte PATCH, 9
.byte PATCH, 10
.byte PATCH, 11
.byte PATCH, 12
.byte PATCH, 13
.byte PATCH, 14
.byte PATCH, 15
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

patch_reload:
	lda inst ; instrument << 4
	lsr ; instrument << 3
	; load patch
	@patch_ptr = write_ptr
	; A = patch * 8
	clc
	adc #<patch_set
	sta @patch_ptr+0
	lda #>patch_set
	adc #0
	sta @patch_ptr+1
	ldx #0
	:
		txa
		tay
		lda (@patch_ptr), Y
		tay
		jsr reg_write
		inx
		cpx #8
		bcc :-
	rts

patch:
	; Y = instrument
	; remember instrument << 4 for register $30 write
	tya
	asl
	asl
	asl
	asl
	sta inst ; inst = patch << 4
	; play test tones at 3 pitches
	.macro TONE low_, high_
		lda #low_
		sta tone0
		lda #high_
		sta tone1
	.endmacro
	TONE $43, $36 ; sustain, trigger, octave 3
	jsr play_tones
	TONE $65, $18 ; no sustain, trigger, octave 4
	jsr play_tones
	TONE $76, $1A ; no sustain, trigger, octave 5
	jsr play_tones
	rts

play_tones:
	jsr lfo_reset
	jsr patch_reload
	ldx #$30
	ldy #0 ; dummy load for matched cycles since lfo_reset
	ldy inst
	jsr reg_write ; original instrument, full volume
	jsr play_tone
	jsr lfo_reset
	jsr patch_reload
	ldx #$30
	ldy inst ; dummy
	ldy #$00
	jsr reg_write ; custom instrument, full volume
	jmp play_tone

play_tone:
	; trigger
	ldx #$10
	ldy tone0
	jsr reg_write ; low 8 bits of tone
	ldx #$20
	ldy tone1
	jsr reg_write ; high bits of tone, begin note
	ldy #120
	jsr swap_delay ; 2s
	; release
	ldx #$20
	lda tone1
	and #%00101111 ; clear trigger
	tay
	jsr reg_write
	ldy #60
	jsr swap_delay ; 1s
	; silence
	ldx #$20
	ldy #$00
	jsr reg_write
	ldy #120
	jsr swap_delay ; 2s
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
