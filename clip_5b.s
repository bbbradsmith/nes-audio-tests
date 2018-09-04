;
; clip_5b.s
;   amplifier compression test for 5B expansion
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

.segment "ZEROPAGE"
rv3: .res 3 ; vol3 broken down into 3 register values

.segment "SWAP"

; 3dB per step until 7, then approximately 1dB per step thereafter, last 4 are .95, .91, .69, .89 as accuracy wanes (see clip_5b_table.ods)
VOL3_STEPS = 42
vol_table0: .byte 0, 1, 2, 3, 4, 5, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9,10,10,10,11,11,11,12,12,12,13,13,13,14,14,14,15,15,15,15,15,15,15,15,15,15,15
vol_table1: .byte 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5, 0, 5, 6, 0, 6, 7, 0, 7, 8, 0, 8, 9, 0, 9,10,12,13,14,15,15,15,15,15
vol_table2: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 3, 0, 0, 4, 0, 0, 5, 0, 0, 6, 0, 0, 7, 0, 0, 8, 7, 8, 8, 3,11,13,14,15

test_registers: ; $20
; not used

test_routines: ; $40
.word init_5b
.word reg
.word vol3
.word tone3
.word tone6
INIT_5B = $40 ; arg ignored
REG     = $41 ; two byte arg: register, value
VOL3    = $42 ; 3 channel volume using vol_table above
TONE3   = $43 ; 3 channel cycle counted tone, 1/2 second
TONE6   = $44 ; like TONE3 but twice has high frequency, 1 seconds

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_5B, 0
.byte DELAY, 60
; 5B DC offset
.repeat VOL3_STEPS, I
	.byte VOL3, I
	.byte DELAY, 10
.endrepeat
.byte DELAY, 50
.byte VOL3, 0
.byte DELAY, 60
; 5B cycle counted tones
.repeat VOL3_STEPS, I
	.byte TONE3, I
.endrepeat
; APU triangle overlay
.byte $08, $FF ; halt counter
.byte $0A, 118 ; 470Hz
.byte $0B, $F0 ; begin APU triangle
.BYTE DELAY, 120
.byte REG, $7, %00111111 ; disable 5B
.byte DELAY, 60
; repeat 5B tests from before, but with triangle now
.repeat VOL3_STEPS, I
	.byte VOL3, I
	.byte DELAY, 10
.endrepeat
.byte DELAY, 50
.byte VOL3, 0
.byte DELAY, 60
.repeat VOL3_STEPS, I
	.byte TONE3, I
.endrepeat
; APU triangle off
.byte $08, $80 ; silence triangle
.byte DELAY, 60
; final test, enable higher frequency sound at highest volume, try to measure attack/release time
.byte TONE6, VOL3_STEPS-1
.byte VOL3, 0
.byte DELAY, 60
.byte $0A, 30 ; ~1800hz triangle
.byte $08, $FF ; begin APU triangle
.byte DELAY, 60
.byte TONE6, VOL3_STEPS-1
.byte VOL3, 0
.byte DELAY, 60
.byte $08, $80 ; silence triangle
.byte DELAY, 60
.byte LOOP

vol3: ; Y = volume 0-18, X not clobbered
	lda vol_table0, Y
	sta rv3+0
	lda vol_table1, Y
	sta rv3+1
	lda vol_table2, Y
	sta rv3+2
	; apply registers
set_rv3:
	.repeat 3, I
		lda #($08 + I)
		sta $C000
		lda rv3+I
		lda rv3+I ; 6 cycles to load rv3+I
		sta $E000
	.endrepeat
	rts

set_0:
	.repeat 3,I
		lda #($08 + I)
		sta $C000
		nop
		nop
		lda #0 ; 6 cycles to load 0
		sta $E000
	.endrepeat
	rts

tone3:
	jsr vol3 ; prepare rv3
	ldx #0 ; alternate at ~1100hz for ~1/2s
	:
		.repeat 2
			jsr swap_delay_768
			jsr set_rv3
			jsr swap_delay_768
			jsr set_0
		.endrepeat
		dex
		bne :- ;  this loop makes it a little rough, but it's good enough
	ldy #10
	jsr swap_delay ; 1/6 second of silence
	rts

tone6: ; ~2200hz for 1 s
	jsr vol3
	ldx #0
	:
		.repeat 8
			jsr swap_delay_384
			jsr set_rv3
			jsr swap_delay_384
			jsr set_0
		.endrepeat
		dex
		bne :-
	rts

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
