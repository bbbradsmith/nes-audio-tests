;
; envelop_5b.s
;   envelope and frequency tests for 5B expansion
;
;   3x 5B tone for 2 seconds + matching APU tone for 2 seconds
;   3x 5B envelope for 2 seconds + matching APU tone for 2 seconds
;   10x single shot ramp envelope triggered 1 second apart, 50Hz step frequency
;
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
; setup
.byte REG, $08, 0 ; 5B: 0 volume
.byte REG, $07, %00111110 ; 5B: tone on
.byte $00, %00110000 ; APU: narrow pulse, constant, 0 volume
.byte $03, $F0 ; APU activate channel
.byte DELAY, 60
; 3x on adjacent period valules:
; 5B plays 2 second tone
; APU adds 2 second tone (narrow pulse) at equivalent frequency
; 1 second pause
BASE_TONE = 25
.repeat 3, I
	.byte REG, $00, BASE_TONE + I
	.byte REG, $08, 10
	.byte DELAY, 120
	.byte $02, ((BASE_TONE*2)-1)+(I*2)
	.byte $00, %00111111
	.byte DELAY, 120
	.byte REG, $08, 0
	.byte $00, %00110000
	.byte DELAY, 60
.endrepeat
; 5B envelope plays 2 second tone
; APU adds 2 second tone (narrow pulse) at equivalent frequency
; 1 second pause
BASE_ENV = 4
.repeat 3, I
	.byte REG, $0B, BASE_ENV + I ; envelope period
	.byte REG, $0D, $08 ; envelope
	.byte REG, $07, %00111111
	.byte REG, $08, $10 ; play envelope on channel
	.byte DELAY, 120
	.byte $02, ((BASE_ENV*32)-1)+(I*32)
	.byte $00, %10111111 ; APU square
	.byte DELAY, 120
	.byte REG, $08, $00
	.byte $00, %10110000
	.byte DELAY, 60
.endrepeat
; envelope sync test
; 10 x plays a low frequency envelope in single shot ramp down
; (50hz per envelope set)
LOW_ENV = 1789772 / (16 * 50) ; 50 steps per second
.byte REG, $0B, <LOW_ENV
.byte REG, $0C, >LOW_ENV
.byte REG, $08, $10 ; play envelope on channel
.repeat 10
	.byte REG, $0D, $00 ; single shot ramp down
	.byte DELAY, 60
.endrepeat
.byte REG, $08, $00

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
