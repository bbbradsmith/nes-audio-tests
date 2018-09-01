;
; db_fds.s
;   relative volume test for FDS expansion
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "db_fds test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00000100
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.segment "SWAP"

test_registers: ; $20
.word $4080
.word $4082
.word $4083
.word $4084
.word $4085
.word $4086
.word $4087
.word $4088
.word $4089
.word $408A
.word $4090
.word $4092
V4080 = $20
V4082 = $21
V4083 = $22
V4084 = $23
V4085 = $24
V4086 = $25
V4087 = $26
V4088 = $27
V4089 = $28
V408A = $29
V4090 = $2A
V4092 = $2B

test_routines: ; $40
.word init_fds
.word wave_square
INIT_FDS = $40 ; arg ignored
WAVE_SQUARE = $41 ; arg ignored

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_FDS, 0
.byte DELAY, 60
; APU 440Hz square
.byte $00, %10111111 ; square duty, constant, full volume
.byte $02, 253 ; (253+1)*16 = 4064 cycle square = ~440.40Hz
.byte $03, $F0
.byte DELAY, 120
.byte $00, %00110000 ; zero volume
.byte DELAY, 60
; FDS 440Hz square
.byte WAVE_SQUARE, 0
PITCH = 1031 ; ~439.9 Hz
.byte V4089, $00 ; full master volume
.byte V4080, $FF ; full volume waveform, envelope disabled
.byte V4082, <(PITCH >> 0)
.byte V4083, <(PITCH >> 8) | $40
.byte DELAY, 120
.byte V4083, $C0 ; halt
.byte V4090, 0 ; zero volume
.byte DELAY, 60
.byte LOOP

init_fds:
	; FDS BIOS reset
	lda #$00
	sta $4023
	lda #$83
	sta $4023 ; reset master IO
	lda #$80
	sta $4080 ; volume 0, envelope disabled
	lda #$EA
	sta $408A ; default envelope speed
	; other stuff
	ldx #$00
	ldy #$80
	stx $4082 ; wav freq
	sty $4083 ; wav disable
	sty $4084 ; mod strength
	stx $4085 ; mod position
	stx $4086 ; mod freq
	sty $4087 ; mod disable
	stx $4089 ; wav write disable
	rts

wave_square:
	lda #$80
	sta $4089 ; wave write enable
	ldx #0
	:
		lda #63
		sta $4040, X
		lda #0
		sta $4060, X
		inx
		cpx #$20
		bcc :-
	lda #$00
	sta $4089 ; wave write disable
	rts

; end of file
