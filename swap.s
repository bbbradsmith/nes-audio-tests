;
; swap.s
;   hotswap test common code
;   https://github.com/bbbradsmith/nes-audio-tests
;

.import test_registers
.import test_routines
.import test_data
.import INES_MAPPER
.importzp INES2_REGION
.importzp NSF_EXPANSION
.importzp SKIP_HOTSWAP

.export swap_load_partial

.include "swap.inc"

.segment "ZEROPAGE"
read_ptr:       .res 2
write_ptr:      .res 2
swap_register:  .res 4 ; self modifying register write (STY abs, RTS)
swap_routine:   .res 3 ; self modifying jsr (JMP abs)

.segment "SWAP"

swap_data: ; startup buzz and wait for swap
.byte BUZZ, 100 ; half second buzz
.byte DELAY, 0 ; 256 frame delay
skip_hotswap:
.byte LOOP

swap_internal:
.word swap_buzz
.word swap_delay
.word swap_init_apu
.word swap_loop

swap:
	; lda 0
	ldy #0
	lda (read_ptr), Y
	asl
	tax ; X = command * 2
	iny
	lda (read_ptr), Y
	tay ; Y = argument
	lda read_ptr+0
	clc
	adc #<2
	sta read_ptr+0
	lda read_ptr+1
	adc #>2
	sta read_ptr+1
	; execute command
	cpx #($20 * 2) ; $00-1F = APU
	bcs :+
		txa
		lsr
		tax
		tya
		sta $4000, X
		jmp swap
	:
	cpx #($40 * 2) ; $20-3F = test_registers
	bcs :+
		lda test_registers-($20*2)+0, X
		sta swap_register+1
		lda test_registers-($20*2)+1, X
		sta swap_register+2
		jsr swap_register
		jmp swap
	:
	cpx #($60 * 2) ; $40-5F = test_routines
	bcs :+
		lda test_routines-($40*2)+0, X
		sta swap_routine+1
		lda test_routines-($40*2)+1, X
		sta swap_routine+2
		jsr swap_routine
		jmp swap
	:
	;                $60-7F = internal routines
		lda swap_internal-($60*2)+0, X
		sta swap_routine+1
		lda swap_internal-($60*2)+1, X
		sta swap_routine+2
		jsr swap_routine
		jmp swap
	;

swap_delay_frame:
	jsr swap_delay_24576
	jsr swap_delay_3072
	jsr swap_delay_1536
	jsr swap_delay_384
	jsr swap_delay_192
	;nop
	;nop
	;nop
	nop
	rts
	; 20 + 192 + 384 + 1536 + 3072 + 24576 = 29780 (approximately NTSC frame)
	; -6 cycles to make it closer in the swap_delay loop

swap_delay_24576: jsr swap_delay_12288
swap_delay_12288: jsr swap_delay_6144
swap_delay_6144:  jsr swap_delay_3072
swap_delay_3072:  jsr swap_delay_1536
swap_delay_1536:  jsr swap_delay_768
swap_delay_768:   jsr swap_delay_384
swap_delay_384:   jsr swap_delay_192
swap_delay_192:   jsr swap_delay_96
swap_delay_96:    jsr swap_delay_48
swap_delay_48:    jsr swap_delay_24
swap_delay_24:    jsr swap_delay_12
swap_delay_12:    rts

swap_delay:
	:
		jsr swap_delay_frame
		dey
		bne :-
	rts

swap_buzz:
	; roughly A440 sawtooth
	ldx #0
	:
		stx $4011
		jsr swap_delay_12
		nop
		nop
		nop
		nop
		nop
		inx
		bne :-
		dey
		bne :-
	stx $4011
	rts

swap_init_apu:
	lda #0
	tax
	:
		sta $4000, X
		inx
		cpx #$16
		bcc :-
	lda #$0F
	sta $4015
	lda #$40
	sta $4017
	rts

swap_loop:
	lda #<test_data
	sta read_ptr+0
	lda #>test_data
	sta read_ptr+1
	rts

.segment "SHARED"

swap_load:
	; copy RAM code
	.import __SWAP_LOAD__
	.import __SWAP_RUN__
	.import __SWAP_SIZE__
	__SWAP_END__ = __SWAP_RUN__ + __SWAP_SIZE__
	@src = read_ptr
	@dst = write_ptr
	lda #<__SWAP_LOAD__
	sta @src+0
	lda #>__SWAP_LOAD__
	sta @src+1
	lda #<__SWAP_RUN__
	sta @dst+0
	lda #>__SWAP_RUN__
	sta @dst+1
	ldy #0
	@load_loop:
		lda (@src), Y
		sta (@dst), Y
		inc @src+0
		bne :+
			inc @src+1
		:
		inc @dst+0
		bne :+
			inc @dst+1
		:
		lda @dst+0
		cmp #<__SWAP_END__
		lda @dst+1
		sbc #>__SWAP_END__
		bcc @load_loop
swap_load_partial:
	; setup self modifying functions on ZP
	lda #$8C ; STY abs
	sta swap_register+0
	lda #$60 ; RTS
	sta swap_register+3
	lda #$4C ; JMP abs
	sta swap_routine+0
	; setup data pointer
	SWAP_DATA = ((SKIP_HOTSWAP <= 0) * swap_data) | ((SKIP_HOTSWAP > 0) * skip_hotswap)
	lda #<SWAP_DATA
	sta read_ptr+0
	lda #>SWAP_DATA
	sta read_ptr+1
	rts

.segment "NES"
nes_reset:
	sei ; disable IRQ
	lda #0
	sta $2000 ; disable NMI
	cld
	ldx #$ff
	txs
	ldx #$00
	stx $2001 ; disable rendering
	stx $4010 ; disable DPCM IRQ
	stx $4015 ; mute APU
	lda #$40
	sta $4017 ; disable APU IRQ
	bit $2002
	: ; warmup frame 1
		bit $2002
		bpl :-
	;ldx #$00
	txa
	: ; clear memory
		sta  $00, X
		sta $100, X
		sta $200, X
		sta $300, X
		sta $400, X
		sta $500, X
		sta $600, X
		sta $700, X
		inx
		bne :-
	: ; warmup frame 2
		bit $2002
		bpl :-
	; load the swap code and begin
	jsr swap_load
	jsr swap_init_apu
	jmp swap

nes_nmi: ; unused
nes_irq: ; unused
	rti

.segment "NSF"
nsf_init:
	jsr swap_load
	rts

nsf_play:
	jsr swap_init_apu
	jmp swap

.segment "NES_HEADER"
.import __ROM_BANK_SIZE__
INES_MIRROR     = 0 ; 0=vertical nametables, 1=horizontal
INES_PRG_16K    = 1 ; 16K
INES_CHR_8K     = 0
INES_BATTERY    = 0
INES2           = %00001000 ; NES 2.0 flag for bit 7
INES2_SUBMAPPER = 0
INES2_PRGRAM    = 0 ; x: 2^(6+x) bytes (0 for none)
INES2_PRGBAT    = 0
INES2_CHRRAM    = 7
INES2_CHRBAT    = 0
.byte 'N', 'E', 'S', $1A ; ID
.byte <INES_PRG_16K
.byte INES_CHR_8K
.byte INES_MIRROR | (INES_BATTERY << 1) | ((<INES_MAPPER & $f) << 4)
.byte (<INES_MAPPER & %11110000) | INES2
; iNES 2 section
.byte (INES2_SUBMAPPER << 4) | <(INES_MAPPER>>8)
.byte ((INES_CHR_8K >> 8) << 4) | (INES_PRG_16K >> 8)
.byte (INES2_PRGBAT << 4) | INES2_PRGRAM
.byte (INES2_CHRBAT << 4) | INES2_CHRRAM
.byte INES2_REGION ; 0 = NTSC, 1 = PAL, 2 = Dual
.byte $00 ; VS system
.byte $00, $00 ; padding/reserved
.assert * = 16, error, "NES header must be 16 bytes."

.segment "VECTORS"
.word nes_nmi
.word nes_reset
.word nes_irq

; NSF header
.segment "NSF_HEADER0"
.byte 'N', 'E', 'S', 'M', $1A ; ID
.byte $01 ; version
.byte 1 ; songs
.byte 1 ; starting song
.word $E000 ; LOAD
.word nsf_init ; INIT
.word nsf_play ; PLAY
;.segment "NSF_HEADER1"
;.byte NSF_TITLE
;.res 32 - .strlen(NSF_TITLE)
;.byte NSF_ARTIST
;.res 32 - .strlen(NSF_ARTIST)
;.byte NSF_COPYRIGHT
;.res 32 - .strlen(NSF_COPYRIGHT)
;.assert * = $6E, error, "NSF strings may be too long?"
.segment "NSF_HEADER2"
.word 16639 ; NTSC speed
.byte 0,0,0,0,0,0,0,0
.word 19997 ; PAL speed
.byte INES2_REGION ; PAL/NTSC bits
.byte NSF_EXPANSION ; expansion bits
.byte 0
.import __ROM_BANK_START__
.import __ROM_BANK_LAST__
.import __NSFE_SUFFIX_SIZE__
NSF_DATA_LEN = (__ROM_BANK_LAST__ - __ROM_BANK_START__) * (__NSFE_SUFFIX_SIZE__ > 0)
.byte <(NSF_DATA_LEN >>  0)
.byte <(NSF_DATA_LEN >>  8)
.byte <(NSF_DATA_LEN >> 16)
.segment "NSFE_SUFFIX"
; empty suffix so that it's always defined

; end of file
