;
; noise_5b.s
;   noise spectrum test for 5B expansion
;
;   56 kHz noise on APU for 6 seconds
;   56 kHz noise on 5B for 6 seconds
;   High frequency tone test periods: 5, 4, 3, 2, 1, 0, 5 (1s each)
;   All 5B noise frequences 0-31, 16 seconds each

;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "noise_5b test", "Brad Smith", "2018 nes-audio-tests"
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
.byte $11, $7F ; APU step for reference
.byte DELAY, 60
.byte $11, $00
.byte DELAY, 60
; APU 56KhZ 1-bit noise
.byte $0C, $3F ; full constant volume
.byte $0E, $03 ; period 3 (32 cycles)
.byte $0F, $FF ; trigger
.byte DELAY, 180
.byte DELAY, 180
.byte $0C, $10 ; 0 volume
.byte DELAY, 60
; 5B noise
.byte REG, $06, $01 ; 32 cycle noise
.byte REG, $08, $0C ; volume 12
.byte REG, $07, %00110111 ; noise on
.byte DELAY, 180
.byte DELAY, 180
.byte REG, $08, $00 ; volume 0
.byte DELAY, 60
; 5B high frequency test
.byte REG, $07, %00111110 ; tone on
.byte REG, $00, 5
.byte REG, $08, $0C
.byte DELAY, 60
.byte REG, $00, 4
.byte DELAY, 60
.byte REG, $00, 3
.byte DELAY, 60
.byte REG, $00, 2
.byte DELAY, 60
.byte REG, $00, 1
.byte DELAY, 60
.byte REG, $00, 0
.byte DELAY, 60
.byte REG, $00, 5
.byte DELAY, 60
.byte REG, $08, $00
.byte DELAY, 60
; 5B all noises 16 seconds each
.byte REG, $07, %00110111
.repeat 32, I
	.byte REG, $08, $0C
	.byte REG, $06, I
	.byte DELAY, 240
	.byte DELAY, 240
	.byte DELAY, 240
	.byte DELAY, 240
	.byte REG, $08, $00
	.byte DELAY, 60
.endrepeat

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
