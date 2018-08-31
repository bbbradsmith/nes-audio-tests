;
; db_n163.s
;   relative volume test for N163 expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_n163 test", "Brad Smith", "2018 nes-audio-tests"
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
.byte REG, $7C, <(PITCH >> 16) | (256-16) ; 16 sample wavelength
.byte REG, $7E, $00 ; address of wave
.byte REG, $7F, $0F ; 1 channel, full volume
.byte DELAY, 120
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
