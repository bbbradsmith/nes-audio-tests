;
; phase_5b.s
;   tone phase tests for 5B expansion
;
;   1. alternate between $FFF and $000 periods 12x (1/3 second each)
;     - when switching to $000, play a quiet 4000Hz tone to mark the transition
;     - note that the long period does not have to finish before the short period takes effect
;     - note lack of determinism for beginnign phase of $FFF (50/50 chance of up or down)
;   2. interrupt $FFF tone with very short periods of $000
;     - note that that makes an effective half-phase "reset"
;   3. halt test to verify that tone/envelope/noise never halts
;      5x half second tone turned off by volume 0
;      5x half second tone turned off by tone disable bit
;      5x half second envelope turned off by channel envelope enable
;      4x 3 second noise burst + half second off by noise disable bit
;     - note it has been verified elsewhere that period 0 does not halt any of these
;       (i.e. period 0 acts as period 1)
;   4. additional test of low volume tone to verify that 0 is actually silent
;     - plays a short 3 tone melody at volumes 2, 1, 0, 3
;   5. additional test of volume 0 vs envelope 0,1,2,3:
;      1 second of 4000Hz tone at volume 0 (silent)
;      2 seconds of rising ramp envelope at 2.1Hz rate, 4+ steps: 0,1,2,3(,4)
;      1 second of tone at volume 0
;      2 seconds of rising ramp envelope at 2.1Hz rate, 4+ steps: 0,1,2,3(,4)
;      1/2 second of tone at volume 1
;      1/2 second of tone at volume 2
;      1 second of volume 0 (silence)
;      1 second of tone at volume 15
;      2 seconds of falling ramp envelope
;      1 second of tone at volume 15
;      2 seconds of falling ramp envelope
;      1/2 second of tone at volume 15
;      1/2 second of tone at volume 14
;      1/2 second of tone at volume 13
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "phase_5b test", "Brad Smith", "2019 nes-audio-tests"
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
.byte REG, $02, 13 ; ~4000Hz "signal" tone on channel 2 to show where change was made
.byte REG, $09, 3  ; channel 2 volume 3 (not enabled yet)
.byte REG, $08, 9  ; channel 1 volume 9 (not enabled yet)
.repeat 12
	; play low frequency (~27hz) on channel 1 for 1/3 s
	.byte REG, $01, $0F
	.byte REG, $00, $FF
	.byte REG, $07, %00111110
	.byte DELAY, 20
	; set channel 1 to lowest frequency and emit signal tone on channel 2
	.byte REG, $00, $00
	.byte REG, $01, $00
	.byte REG, $07, %00111100
	.byte DELAY, 20
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60
; demonstrate phase reset
.byte REG, $07, %00111110 ; activate channel 1
.byte REG, $08, 9
.repeat 12
	; 50/50 "reset" of phase by switching to frequency 0 very briefly
	.byte REG, $00, $00 ; ~56kHz
	.byte REG, $01, $00
	.byte REG, $01, $0F ; ~27Hz
	.byte REG, $00, $FF
	.byte DELAY, 20
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60

; halt tests
; tone on/off
.byte REG, $01, 2 ; ~109 Hz
.byte REG, $07, %00111110
.repeat 5
	.byte REG, $08, 9
	.byte DELAY, 30
	.byte REG, $08, 0
	.byte DELAY, 30
.endrepeat
.byte REG, $08, 9
.repeat 5
	.byte REG, $07, %00111110
	.byte DELAY, 30
	.byte REG, $07, %00111111
	.byte DELAY, 30
.endrepeat
; envelope on/off
.byte REG, $0B, 16 ; ~109 Hz
.byte REG, $0D, $0A ; triangle
.repeat 5
	.byte REG, $08, $10
	.byte DELAY, 30
	.byte REG, $08, $00
	.byte DELAY, 30
.endrepeat
; noise on/off
; noise is at period 0 from INIT_5B
.byte REG, $08, 9
.repeat 4
	.byte REG, $07, %00110111
	.byte DELAY, 180
	.byte REG, $07, %00111111
	.byte DELAY, 30
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60

; test of volume 2,1,0,3
; play 3 tones on each
.byte REG, $07, %00111110
.repeat 4, I
	.byte REG, $08, (2-I)&3
	.byte REG, $00, 250
	.byte DELAY, 40
	.byte REG, $00, 200
	.byte DELAY, 40
	.byte REG, $00, 150
	.byte DELAY, 40
.endrepeat
.byte INIT_5B, 0
.byte DELAY, 60

; test of volume 0 vs disabled tone or envelope 0
.byte REG, $00, 13 ; 8000 signal just to make sure it comes through
; tone enable, volume 0
.byte REG, $07, %00111110
.byte DELAY, 60
; tone + envelope rising from 0
ENV_2HZ = 53267 ; 2.1Hz
.byte REG, $0B, <ENV_2HZ
.byte REG, $0C, >ENV_2HZ
.byte REG, $0D, $0D ; one-shot rising ramp
.byte REG, $08, $10 ; enable envelope instead of volume
.byte DELAY, 120 ; execute 4+ steps of envelope
.byte REG, $08, $00 ; return to 0
.byte DELAY, 60
; repeat tone+envelope rise
.byte REG, $0D, $0D
.byte REG, $08, $10
.byte DELAY, 120
; volume 1 and 2 for comparison
.byte REG, $08, $01
.byte DELAY, 30
.byte REG, $08, $02
.byte DELAY, 30
; 1 second silence
.byte REG, $08, $00
.byte DELAY, 60

; test of volume 15 vs disabled tone or envelope 0
; tone at volume 15
.byte REG, $08, $0F
.byte DELAY, 60
; tone + envelope falling from maximum
.byte REG, $0D, $01 ; one-shot falling ramp
.byte REG, $08, $10
.byte DELAY, 120 ; execute 4+ steps of envelope
.byte REG, $08, $0F ; return to 15
.byte DELAY, 60
; repeat tone + envelope fall
.byte REG, $0D, $01
.byte REG, $08, $10
.byte DELAY, 120 ; execute 4+ steps of envelope
; volume 15, 14, 13 for comparison
.byte REG, $08, $0F
.byte DELAY, 30
.byte REG, $08, $0E
.byte DELAY, 30
.byte REG, $08, $0D
.byte DELAY, 30

; end
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
