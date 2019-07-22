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

; plays simulated noise (period $6) on DAC for 2s + .5s silence
; Y = volume (0-127)
.export dmc_noise
.export dmc_noise_init

; plays simulated square (period 253) on DAC for 2s + .5s silence
; Y = volume (0-127)
.export dmc_square

; begins playing triangle at frequency minimum, maximum, 440Hz
.export tri_min ; 2048 cy step, 65536 cy period, 27.310 Hz
.export tri_max ; 1 cy step, 32 cy period, 55930 Hz

; plays triangle 440Hz for 2s + .5s "silence" (tri max)
.export tri_440 ; 127 cy step, 4064 cy period, 440.40 Hz

; un-halt a tri_min for 1 second and halt again after advancing a single step
.export tri_min_cycle

; plays noise channel (period $6) for 2s + .5s silence
; Y = volume (0-15)
.export noise_6

; plays square 440Hz for 2s + .5s silence
; Y = volume (0-15)
.export square_440

INES2_REGION = 0 ; 1 for PAL region
.exportzp INES2_REGION

; These routines aren't intended for hotswaps,
; but moving them to SWAP instead of SHARED,
; and changing this to 0 would be sufficient to allow it.
SKIP_HOTSWAP = 1
.exportzp SKIP_HOTSWAP

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

.segment "SHARED"

; 32 bytes 0-15, 15-0
; repeated 4x as: *1, *2, *4, *8
.align 128
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
; equivalent to triangle with period register 126
.align 64
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
	;                       ;    = 110
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
; 128 NTSC (118 PAL) cycles per sample (13983 Hz)
; equivalent to noise with period register $6
.align 64
dmc_noise:
	; Y = volume of output
	lda #109 ; 109 * 256 * 128 = 3571712 cycles = 1.996 seconds
	sta dmc_loops
	;         cycles since last sample
@sample256:
	;                       ;    =  74
	ldx #0                  ; +2 =  76
@sample:
	;                       ;    =  76
	; NTSC requires 10 more cycles than PAL
	.if INES2_REGION <> 1
	    nop                 ; +2 =  78
	    nop                 ; +2 =  80
	    nop                 ; +2 =  82
	    nop                 ; +2 =  84
	    nop                 ; +2 =  86
	.endif
	; lsfr = lfsr << 1
	lda noise_lfsr+1        ; +3 =  89
	asl noise_lfsr+0        ; +5 =  94
	rol noise_lfsr+1        ; +5 =  99
	; feedback = previous bits 13 ^ 14
	eor noise_lfsr+1        ; +3 = 102
	and #$40                ; +2 = 104
	asl                     ; +2 = 106
	asl                     ; +2 = 108
	rol                     ; +2 = 110
	; feedback into vacated bit 0
	ora noise_lfsr+0        ; +3 = 113
	sta noise_lfsr+0        ; +3 = 116
	lda noise_lfsr+1        ; +3 = 119
	; output = previous bit 14 (now in 15)
	rol                     ; +2 = 121
	bcs :+                  ; +2 = 123
	assert_branch_page :+
	    nop3                ; +3 = 126
	    nop                 ; +2 = 128
	    ; write sample      ;    =   0
	    sty $4011           ; +4 =   4
	    jmp :++             ; +3 =   7
	:
	;bcs :+                 ; +3 = 124
	    nop                 ; +2 = 126
	    lda #0              ; +2 = 128
	    ; write sample      ;    =   0
	    sta $4011           ; +4 =   4
	    nop3                ; +3 =   7
	:
	inx                     ; +2 =   9
	beq @sample256_next     ; +2 =  11
	assert_branch_page @sample256_next
	jsr swap_delay_48       ;+48 =  59
	jsr swap_delay_12       ;+12 =  71
	nop                     ; +2 =  73
	jmp @sample             ; +3 =  76
@sample256_next:
	;beq @sample256_next    ; +3 =  12
	jsr swap_delay_48       ;+48 =  60
	nop                     ; +2 =  62
	nop                     ; +2 =  64
	nop                     ; +2 =  66
	dec dmc_loops           ; +5 =  71
	bne @sample256          ; +3 =  74
	assert_branch_page @sample256
	; finish with 0.5s silence
	jmp dmc_finish_silence

dmc_noise_init:
	ldy #0
	sty noise_lfsr+1
	iny
	sty noise_lfsr+0
	rts

; plays ~2 second square + 0.5s silence
; 2032 cycles per flip (440.40 Hz)
; equivalent to square with period register 253
.align 64
dmc_square:
	; Y = volume of output
	; 886 * 4064 = 3600704 cycles = 2.012 seconds
	lda #1+>886
	sta dmc_loops
	ldx #256-<886
	lda #0
	jmp @sample
@sample256:
	;                       ;     = 2030
	ldx #0                  ;  +2 = 2032
@sample:
	; high sample           ;     =    0
	sty $4011               ;  +4 =    4
	jsr swap_delay_1536     ;1536 = 1540
	jsr swap_delay_384      ;+384 = 1924
	jsr swap_delay_96       ; +96 = 2020
	jsr swap_delay_12       ; +12 = 2032
	; low sample            ;     =    0
	sta $4011               ;  +4 =    4
	jsr swap_delay_1536     ;1536 = 1540
	jsr swap_delay_384      ;+384 = 1924
	jsr swap_delay_48       ; +48 = 1972
	inx                     ;  +2 = 1974
	beq @sample256_next     ;  +2 = 1976
	assert_branch_page @sample256_next
	jsr swap_delay_48       ; +48 = 2024
	nop3                    ;  +3 = 2027
	nop                     ;  +2 = 2029
	jmp @sample             ;  +3 = 2032
@sample256_next:
	;beq @sample256_next    ;  +3 = 1977
	jsr swap_delay_24       ; +24 = 2001
	jsr swap_delay_12       ; +12 = 2013
	nop3                    ;  +3 = 2016
	nop                     ;  +2 = 2018
	nop                     ;  +2 = 2020
	dec dmc_loops           ;  +5 = 2025
	bne @sample256          ;  +3 = 2030
	assert_branch_page @sample256
	; finish with 0.5s silence
	jmp dmc_finish_silence

tri_setup:
	lda #$FF
	sta $4008 ; freeze length/linear counter
	rts

tri_min:
	jsr tri_setup
	lda #$FF
	sta $400A ; freq low = $FF
	lda #$FF
	sta $400B ; freq high = $7, reload counter
	rts

tri_max:
	jsr tri_setup
	lda #0
	sta $400A ; freq low = 0
	lda #$F0
	sta $400B ; freq high = 0, reload counter
	rts

tri_440:
	jsr tri_setup
	lda #126
	sta $400A
	lda #$F0
	sta $400B
	ldy #120
	jsr swap_delay
	jsr tri_max ; "silence" via max frequency
	ldy #30
	jmp swap_delay

; succinct longer cycle delays
;                                                internal => from jsr (+6)
long_delay6: jsr long_delay5 ; (786810 * 2) + 6 = 1573626 => 1573632
long_delay5: jsr long_delay4 ; (393402 * 2) + 6 = 786810  =>  786816
long_delay4: jsr long_delay3 ; (196698 * 2) + 6 = 393402  =>  393408
long_delay3: jsr long_delay2 ; (98346  * 2) + 6 = 196698  =>  196704
long_delay2: jsr long_delay1 ; (49170  * 2) + 6 = 98346   =>   98352
long_delay1: jsr long_delay0 ; (24582  * 2) + 6 = 49170   =>   49176
long_delay0: jsr swap_delay_24576 ;  24576  + 6 = 24582   =>   24588
	rts ; + 6

tri_min_cycle:
	lda #%00001111
	sta $4015
	lda #$FF
	sta $400B ; freq high = $7, reload length counter (resume)
	; each step is 2048 cycles
	; ~1 second delay is about 27 periods
	; run for ~1 second + 1 step:
	; ((27 * 32) + 1) * 2048 = 1771520 cycles
	jsr long_delay6 ; 1771520 - 1573632 = 197888
	jsr long_delay3 ; 197888 - 196704 = 1184
	jsr swap_delay_768 ; 1184 - 768 = 416
	jsr swap_delay_384 ; 416 - 384 = 32
	jsr swap_delay_24 ; 32 - 24 = 8
	nop ; 8 - 2 = 6
	lda #%00001011   ; 6 - 2 = 4
	sta $4015 ; 4 - 4 = 0 (triangle off)
	rts

; plays 2 second noise + 0.5s silence (period $6)
; Y = volume (0-15)
noise_6:
	tya
	ora #%00110000
	sta $400C ; freeze length counter, constant volume
	lda #$06
	sta $400E ; period = $6 (not periodic)
	lda #$FF
	sta $400F ; reload counter
	ldy #120
	jsr swap_delay
	lda #%00110000
	sta $400C ; silence
	ldy #30
	jmp swap_delay

; plays 2 seconds square + 0.5s silence (period 253 = 440Hz)
; Y = volume (0-15)
square_440:
	tya
	ora #%10110000 ; square duty, constant volume
	sta $4000
	lda #253 ; (253+1)*16 = 4064 cycle square = ~440.40 Hz
	sta $4002
	lda #$F0
	sta $4003 ; begin
	ldy #120
	jsr swap_delay
	lda #%10110000
	sta $4000 ; silence
	ldy #30
	jmp swap_delay

; end of file
