;
; swap_fds.s
;   FDS packaging code for hotswap test
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"
.import swap_load_partial

.segment "FDS"

fds_irq:
fds_nmi:
	rti

fds_bypass:
	; disable NMI
	lda #0
	sta $2000
	; replace NMI 3 "bypass" vector at $DFFA
	lda #<fds_nmi
	sta $DFFA
	lda #>fds_nmi
	sta $DFFB
	; tell the FDS reset routine that the BIOS initialized correctly
	lda #$35
	sta $0102
	lda #$AC
	sta $0103
	; reset the FDS to begin our program properly
	jmp ($FFFC)

fds_reset:
	lda $FA
	and #%11110111
	sta $4025
	sei       ; mask interrupts
	lda #0
	sta $2000 ; disable NMI
	sta $2001 ; disable rendering
	sta $4015 ; disable APU sound
	sta $4010 ; disable DMC IRQ
	lda #$40
	sta $4017 ; disable APU IRQ
	cld       ; disable decimal mode
	ldx #$FF
	txs       ; initialize stack
	; wait for 2 vblanks
	bit $2002
	:
		bit $2002
		bpl :-
	:
		bit $2002
		bpl :-
	; clear all RAM that wasn't part of SWAP
	.import __SWAP_RUN__
	.import __SWAP_SIZE__
	ldx #0
	ldy #2
	@loop:
		txa
		cmp #<__SWAP_RUN__
		tya
		sbc #>__SWAP_RUN__
		bcc @clear
		txa
		cmp #<(__SWAP_RUN__ + __SWAP_SIZE__)
		tya
		sbc #>(__SWAP_RUN__ + __SWAP_SIZE__)
		bcs @clear
		jmp @skip
	@clear:
		stx $00
		sty $01
		ldy #0
		tya
		sta ($00), Y
		ldy $01
	@skip:
		inx
		bne :+
			iny
			cpy #$08
			bcs @end
		:
		jmp @loop
	@end:
	; clear ZP
	ldx #0
	txa
	:
		sta $00, X
		inx
		bne :-
	; begin SWAP
	jsr swap_load_partial
	jsr swap_init_apu
	jmp swap

; FDS file

FILE_COUNT = 4 + 1 ; +1 causes loader to keep looking, giving NMI time to fire for bypass

.segment "HEADER"
.byte "FDS",$1A
.byte 1 ; side count

.segment "FDS0"
; block 1
.byte $01
.byte "*NINTENDO-HVC*"
.byte $00 ; manufacturer
.byte "EXA"
.byte $20 ; normal disk
.byte $00 ; game version
.byte $00 ; side
.byte $00 ; disk
.byte $00 ; disk type
.byte $00 ; unknown
.byte FILE_COUNT ; boot file count
.byte $FF,$FF,$FF,$FF,$FF
.byte $93 ; 2018
.byte $08 ; august
.byte $31 ; 31
.byte $49 ; country
.byte $61, $00, $00, $02, $00, $00, $00, $00, $00 ; unknown
.byte $93 ; 2018
.byte $08 ; august
.byte $31 ; 31
.byte $00, $80 ; unknown
.byte $00, $00 ; disk writer serial number
.byte $07 ; unknown
.byte $00 ; disk write count
.byte $00 ; actual disk side
.byte $00 ; unknown
.byte $00 ; price

; block 2
.byte $02
.byte FILE_COUNT

; file 0 (code)
.byte $03
.byte 0,0
.byte "CODE...."
.import __RAM_FDS_START__
.import __RAM_FDS_LAST__
.word __RAM_FDS_START__
.word (__RAM_FDS_LAST__ - __RAM_FDS_START__)
.byte 0 ; PRG
.byte $04
; .segment "SHARED"
; .segment "FDS"

.segment "FDS1"
; file 1 (swap)
.byte $03
.byte 1,1
.byte "SWAP...."
.import __SWAP_RUN__
.import __SWAP_SIZE__
.word __SWAP_RUN__
.word __SWAP_SIZE__
.byte 0 ; PRG
.byte $04
;.segment "SWAP"

.segment "FDS2"
; file 2 (vectors)
.byte $03
.byte 2,2
.byte "VECTORS."
.word $DFF6
.word 10
.byte 0
.byte $04
.word fds_nmi
.word fds_nmi
.word fds_bypass
.word fds_reset
.word fds_irq

; file 3 (bypass)
.byte $03
.byte 3,3
.byte "BYPASS.."
.word $2000
.word 1
.byte 0 ; PRG
.byte $04
.byte $90 ; writing this to $2000 enabled NMI and bypasses license screen

; end of file
