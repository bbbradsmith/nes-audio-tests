;
; phase_5b.s
;   tone phase tests for 5B expansion
;
;   1. alternate between $FFF and $000 periods 12x (1/3 second each)
;     - when switching to $000, play a quiet 8000Hz tone to mark the transition
;     - note that the long period does not have to finish before the short period takes effect
;     - note lack of determinism for beginnign phase of $FFF (50/50 chance of up or down)
;   2. interrupt $FFF tone with very short periods of $000
;     - note that that makes an effective half-phase "reset"
;   3. additional test of low volume tone to verify that 0 is actually silent
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "phase_5b test", "Brad Smith", "2019 nes-audio-tests"
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
; setup
.byte REG, $02, 13 ; ~8000Hz "signal" tone on channel 2 to show where change was made
.byte REG, $09, 3  ; channel 2 volume 3 (not enabled yet)
.byte REG, $08, 9  ; channel 1 volume 9 (not enabled yet)
.repeat 12
	; play low frequency (~27hz) on channel 1 for 1/3 s
	.byte REG, $01, $0F
	.byte REG, $00, $FF
	.byte REG, $07, %00111110
	.byte DELAY, 20
	; set channel 1 to lowest frequency and emit signal tone on channel 2
	.byte REG, $00, $00
	.byte REG, $01, $00
	.byte REG, $07, %00111100
	.byte DELAY, 20
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60
; demonstrate phase reset
.byte REG, $07, %00111110 ; activate channel 1
.byte REG, $08, 9
.repeat 12
	; 50/50 "reset" of phase by switching to frequency 0 very briefly
	.byte REG, $00, $00 ; ~56kHz
	.byte REG, $01, $00
	.byte REG, $01, $0F ; ~27Hz
	.byte REG, $00, $FF
	.byte DELAY, 20
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60
; test of volume 2,1,0,3
; play 3 tones on each
.byte REG, $07, %00111110
.repeat 4, I
	.byte REG, $08, (2-I)&3
	.byte REG, $00, 250
	.byte DELAY, 40
	.byte REG, $00, 200
	.byte DELAY, 40
	.byte REG, $00, 150
	.byte DELAY, 40
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60
; loop
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
