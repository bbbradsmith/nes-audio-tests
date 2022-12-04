;
; test_n163_longwave.s
;   test of N163 length register upper bits
;   https://github.com/bbbradsmith/nes-audio-tests
;
; Plays A440 square on APU
; Then plays an equivalent square wave on N163 with different length register values,
; each for 1 second:
;
; %11110000 =  16 (A440.0)
; %11100000 =  32 (A220.0)
; %11010000 =  48 (D146.6)
; %11000000 =  64 (A110.0)
; %10100000 =  96 (D 73.3)
; %10000000 = 128 (A 55.0)
; %01000000 = 192
; %00100000 = 224
; %00010000 = 240
; %00001000 = 248 (from here on, samples will includes some of the channel parameters)
; %00000100 = 252
; %00000000 = 256 (A 22.5)

.include "swap.inc"

NSF_STRINGS "test_n163_longwave", "Brad Smith", "2022 nes-audio-tests"
NSF_EXPANSION = %00010000
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "SWAP"

test_registers: ; $20
.word $F800
.word $4800
ADDR = $20
DATA = $21

test_routines: ; $40
.word init_n163
.word reg
INIT_N163 = $40 ; arg ignored
REG       = $41 ; two byte arg: register, value

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_N163, 0
.byte DELAY, 60
; APU 440Hz square
.byte $00, %10111111 ; square duty, constant, full volume
.byte $02, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte $03, $F0
.byte DELAY, 120
.byte $00, %00110000 ; zero volume
.byte DELAY, 60
; N163 440Hz square
.byte ADDR, $80 ; 16 sample square waveform at $00
.byte DATA, $FF
.byte DATA, $FF
.byte DATA, $FF
.byte DATA, $FF
.byte DATA, $00
.byte DATA, $00
.byte DATA, $00
.byte DATA, $00
PITCH = 3867 ; ~440.0 Hz
.byte REG, $78, <(PITCH >>  0)
.byte REG, $7A, <(PITCH >>  8)
.byte REG, $7E, $00 ; address of wave
.byte REG, $7F, $0F ; 1 channel, full volume
.byte REG, $7C, <(PITCH >> 16) | %11110000, DELAY, 60 ; 16 (A440)
.byte REG, $7C, <(PITCH >> 16) | %11100000, DELAY, 60 ; 32
.byte REG, $7C, <(PITCH >> 16) | %11010000, DELAY, 60 ; 48
.byte REG, $7C, <(PITCH >> 16) | %11000000, DELAY, 60 ; 64
.byte REG, $7C, <(PITCH >> 16) | %10100000, DELAY, 60 ; 96
.byte REG, $7C, <(PITCH >> 16) | %10000000, DELAY, 60 ; 128
.byte REG, $7C, <(PITCH >> 16) | %01000000, DELAY, 60 ; 192
.byte REG, $7C, <(PITCH >> 16) | %00100000, DELAY, 60 ; 224
.byte REG, $7C, <(PITCH >> 16) | %00010000, DELAY, 60 ; 240
.byte REG, $7C, <(PITCH >> 16) | %00001000, DELAY, 60 ; 248
.byte REG, $7C, <(PITCH >> 16) | %00000100, DELAY, 60 ; 252
.byte REG, $7C, <(PITCH >> 16) | %00000000, DELAY, 60 ; 256
.byte REG, $7F, $00 ; 1 channel, 0 volume
.byte DELAY, 60
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
	stx $F800
	sty $4800
	rts

init_n163:
	ldx #0
	stx $E000 ; enable sound
	ldy #$80
	sty $F800
	ldy #0
	: ; 0 to all registers
		sty $4800
		inx
		cpx #$80
		bcc :-
	rts

; end of file
