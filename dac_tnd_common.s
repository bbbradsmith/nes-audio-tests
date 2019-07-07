;
; dac_tnd_common.s
;   test of APU triangle/noise/DMC nonlinear DAC
;   https://github.com/bbbradsmith/nes-audio-tests
;

;
; common routines for the dac_tnd tests
;

; plays simulated triangle (period 126) on DAC for 2s + .5s silence
; Y -> volume (0,1,2,3) = (15,30,60,120)
.export dmc_triangle

; plays simulated noise (period $B) on DAC for 2s + .5s silence
; Y = volume (0-127)
.export dmc_noise
.export dmc_noise_init

INES2_REGION = 0 ; 1 for PAL region
.exportzp INES2_REGION

.include "swap.inc"

; place immediately after branch to prevent page crossing
.macro assert_branch_page label_
	.assert >(label_) = >*, error, "Page crossing detected!"
.endmacro

; 3 cycle nop
.macro nop3
	jmp *+3
.endmacro

.segment "ZEROPAGE"

triangle_table_add: .res 1
dmc_loops: .res 1
noise_lfsr: .res 1

.segment "SWAP"

.align 128
; 32 bytes 0-15, 15-0
; repeated 4x as: *1, *2, *4, *8
triangle_table:
	.repeat 4, M
		.repeat 16, I
			.byte I<<M
		.endrepeat
		.repeat 16, I
			.byte (15-I)<<M
		.endrepeat
	.endrepeat

; plays ~2 second triangle + 0.5s silence
; 127 cycles per sample (440.40 Hz)
; equivalent to triangle with period register 126)
.align 128
dmc_triangle:
	; Y = 0,1,2,3 (<< on output)
	tya
	and #3
	asl
	asl
	asl
	asl
	asl
	sta triangle_table_add
	lda #110 ; 110 * 256 * 127 = 3576320 cycles = 1.998 seconds
	sta dmc_loops
	;         cycles since last sample
@sample256:
	;                              110
	ldx #0                  ; +2 = 112
@sample:
	txa                     ; +2 = 114
	and #31                 ; +2 = 116
	clc                     ; +2 = 118
	adc triangle_table_add  ; +3 = 121
	tay                     ; +2 = 123
	lda triangle_table, Y   ; +4 = 127
	; write sample          ;    =   0
	sta $4011               ; +4 =   4
	inx                     ; +2 =   6
	beq @sample256_next     ; +2 =   8
	assert_branch_page @sample256_next
	jsr swap_delay_96       ;+96 = 104
	nop3                    ; +3 = 107
	nop                     ; +2 = 109
	jmp @sample             ; +3 = 112
@sample256_next:
	;beq @sample256_next    ; +3 =   9
	jsr swap_delay_48       ;+48 =  57
	jsr swap_delay_24       ;+24 =  81
	jsr swap_delay_12       ;+12 =  93
	nop3                    ; +3 =  96
	nop                     ; +2 =  98
	nop                     ; +2 = 100
	nop                     ; +2 = 102
	dec dmc_loops           ; +5 = 107
	bne @sample256          ; +3 = 110
	assert_branch_page @sample256
	; finish with 0.5s silence
dmc_finish_silence:
	lda #0
	sta $4011
	ldy #30
	jmp swap_delay

; plays ~2 second noise + 0.5s silence
; 508 NTSC (472 PAL) cycles per sample (3523 Hz)
; equivalent to noise with period register $B
.align 128
dmc_noise:
	; Y = volume of output
	lda #28 ; 28 * 256 * 508 = 3641344 cycles = 2.035 seconds
	sta dmc_loops
	;         cycles since last sample
@sample256:
	;                              428
	ldx #0                  ; +2 = 430
@sample:
	;                       ;    = 430
	; NTSC requires 36 more cycles than PAL
	.if INES2_REGION <> 1
	    jsr swap_delay_24   ;+24 = 454
	    jsr swap_delay_12   ;+12 = 466
	.endif
	; lsfr = lfsr << 1
	lda noise_lfsr+1        ; +3 = 469
	asl noise_lfsr+0        ; +5 = 474
	rol noise_lfsr+1        ; +5 = 479
	; feedback = previous bits 13 ^ 14
	eor noise_lfsr+1        ; +3 = 482
	and #$40                ; +2 = 484
	asl                     ; +2 = 486
	asl                     ; +2 = 488
	rol                     ; +2 = 490
	; feedback into vacated bit 0
	ora noise_lfsr+0        ; +3 = 493
	sta noise_lfsr+0        ; +3 = 496
	lda noise_lfsr+1        ; +3 = 499
	; output = previous bit 14 (now in 15)
	rol                     ; +2 = 501
	bcc :+                  ; +2 = 503
	assert_branch_page :+
	    nop3                ; +3 = 506
	    nop                 ; +2 = 508
	    ; write sample      ;    =   0
	    sty $4011           ; +4 =   4
	    jmp :++             ; +3 =   7
	:
	;bcc :+                 ; +3 = 504
	    nop                 ; +2 = 506
	    lda #0              ; +2 = 508
	    ; write sample      ;    =   0
	    sta $4011           ; +4 =   4
	    nop3                ; +3 =   7
	:
	inx                     ; +2 =   9
	beq @sample256_next     ; +2 =  11
	assert_branch_page @sample256_next
	jsr swap_delay_384      ;384 = 395
	jsr swap_delay_24       ;+24 = 419
	nop                     ; +2 = 421
	nop                     ; +2 = 423
	nop                     ; +2 = 425
	nop                     ; +2 = 427
	jmp @sample             ; +3 = 430
@sample256_next:
	;beq @sample256_next    ; +3 =  12
	jsr swap_delay_384      ;384 = 396
	jsr swap_delay_24       ;+24 = 420
	dec dmc_loops           ; +5 = 425
	bne @sample256          ; +3 = 428
	assert_branch_page @sample256
	; finish with 0.5s silence
	jmp dmc_finish_silence

dmc_noise_init:
	ldy #0
	sty noise_lfsr+1
	iny
	sty noise_lfsr+0
	rts

; end of file
