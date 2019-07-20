;
; dac_square.s
;   test of APU square nonlinear DAC
;   https://github.com/bbbradsmith/nes-audio-tests
;
; 00:00-10:40
;
; This produces a 2 second A440 square wave on one or both APU square channels,
; using all 256 possible combinations of volume setting.
; Each tone is separated by 1/2 second of silence.
;
; See misc/dac.py for a program to analyze the output.
;

.include "swap.inc"

NSF_STRINGS "dac_square test", "Brad Smith", "2019 nes-audio-tests"
NSF_EXPANSION = %00000000
SKIP_HOTSWAP = 1

.export test_registers
.export test_routines
.export test_data
.exportzp SKIP_HOTSWAP
.exportzp NSF_EXPANSION

.segment "SWAP"

PERIOD = 253  ; (253+1)*16 = 4064 cycle square = ~440.40Hz

test_registers: ; $20
; not used

test_routines: ; $40
.word dac_square_test
DAC_SQUARE_TEST = $40 ; arg = 0-255

dac_square_test:
	ldx #0
@loop:
	; resynchronize
	lda #0
	sta $4002
	sta $4006

	; set two volumes from X nibbles
	txa
	lsr
	lsr
	lsr
	lsr
	ora #%10110000
	tay
	txa
	and #%00001111
	ora #%10110000
	sta $4000
	sty $4004
	; reset phase
	lda #0 ; shortest possible step period to synchronize period counters
	sta $4002
	sta $4006
	lda #<PERIOD ; A440
	sta $4002
	sta $4006
	lda #($F8 | >PERIOD) ; reset phase
	sta $4003
	sta $4007
	; 2 seconds
	ldy #120
	jsr swap_delay
	; silence 0.5 seconds
	lda #%10110000
	sta $4000
	sta $4004
	ldy #30
	jsr swap_delay
	inx
	bne @loop
	rts

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte DELAY, 60
.byte DAC_SQUARE_TEST, 0
.byte DELAY, 60
.byte LOOP

; end of file
