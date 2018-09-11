;
; sweep_5b.s
;   sweep and noise spectrum test for 5B expansion:
;   - approximated sine wave at ~17376Hz samplerate (103 cycles)
;   - 1-bit noise at ~56kHz (32 cycles)
;   first sweep is APU, second sweep is 5B
;   sweep is approximately logarithmic, ~2.67 seconds per octave
;   
;   https://github.com/bbbradsmith/nes-audio-tests
;

.include "swap.inc"

NSF_STRINGS "sweep_5b test", "Brad Smith", "2018 nes-audio-tests"
NSF_EXPANSION = %00100000
INES2_REGION = 0 ; NTSC only

.export test_registers
.export test_routines
.export test_data
.exportzp NSF_EXPANSION
.exportzp INES2_REGION

.macro branch_page label_
	.assert >(label_) = >(*), error, "Branch will cross page!"
.endmacro

.segment "ZEROPAGE"
sweep_p: .res 3 ; phase of sweep, high byte looks up a sine table
sweep_i: .res 3 ; increment of sweep controls pitch, added to phase each iteration
sweep_t: .res 3 ; temporary sweep_i
sweep_a: .res 2 ; quasi-logarithmic increment of increment
sweep_f: .res 2 ; function pointer for the value write fuction

.segment "SWAP"

.align 256
sine_dmc:
.include "sine_dmc.inc"

.align 256
sine_5b:
.include "sine_5b.inc"

sweep_loop:
	ldy #0
	@sample:
		jsr swap_delay_24 ; 24
	@next:
		jsr sweep_iter    ; 43
		jsr sweep_write   ; 31 = 103 since last sweep_write (43 + 31 + 29)
		dey               ; 2
		bne @sample       ; 2 / 3
		branch_page @sample
	; increment pitch, store as temporary (t = i + a)
	lda sweep_a+0 ; 3
	clc           ; 2
	adc sweep_i+0 ; 3
	sta sweep_t+0 ; 3
	lda sweep_a+1 ; 3
	adc sweep_i+1 ; 3
	sta sweep_t+1 ; 3
	php           ; 3 (store carry)
	nop           ; 2 = 29
	jsr sweep_iter
	jsr sweep_write
	plp           ; 4
	lda sweep_i+2 ; 3
	adc #0        ; 2
	sta sweep_t+2 ; 3
	bcs @finish   ; 2 (carry ends iteration)
	; a = (i / 256) + 1 (quasi-logarithmic acceleration of pitch increment)
	lda sweep_t+1 ; 3
	clc           ; 2
	adc #1        ; 2
	sta sweep_a+0 ; 3
	php           ; 3
	nop           ; 2 = 29
	jsr sweep_iter
	jsr sweep_write
	plp           ; 4
	lda sweep_t+2 ; 3
	adc #0        ; 2
	sta sweep_a+1 ; 3
	jsr swap_delay_12
	bit sweep_p+0 ; 3
	nop           ; 2 = 29
	jsr sweep_iter
	jsr sweep_write
	; i = t (copy temporary to pitch increment before the next sample)
	lda sweep_t+0 ; 3
	sta sweep_i+0 ; 3
	lda sweep_t+1 ; 3
	sta sweep_i+1 ; 3
	lda sweep_t+2 ; 3
	sta sweep_i+2 ; 3
	ldy #0        ; 2
	jmp @next     ; 3 = 29
@finish:
	rts

sweep_iter:       ; 6
	lda sweep_i+0 ; 3
	clc           ; 2
	adc sweep_p+0 ; 3
	sta sweep_p+0 ; 3
	lda sweep_i+1 ; 3
	adc sweep_p+1 ; 3
	sta sweep_p+1 ; 3
	lda sweep_i+2 ; 3
	adc sweep_p+2 ; 3
	sta sweep_p+2 ; 3
	tax           ; 2
	rts           ; 6 = 43

sweep_write:      ; 6
	jmp (sweep_f) ; 5

sweep_common:
	ldx #0
	stx sweep_p+0
	stx sweep_p+1
	stx sweep_p+2
	stx sweep_i+1
	stx sweep_i+2
	stx sweep_a+1
	ldx #1
	stx sweep_i+0
	stx sweep_a+0
	; centring pop
	ldx #0
	jsr sweep_write
	ldy #60
	jsr swap_delay
	jmp sweep_loop

sweep_write_apu:    ; 11 (jsr + jmp)
	lda sine_dmc, X ; 4
	sta $4011       ; 4
	nop             ; 2
	nop             ; 2
	nop             ; 2
	rts             ; 6 = 31

sweep_write_5b:    ; 11 (jsr + jmp)
	lda sine_5b, X ; 4
	ldx #$08       ; 2
	stx $C000      ; 4
	sta $E000      ; 4
	rts            ; 6 = 31

sweep_5b:
	lda #<sweep_write_5b
	sta sweep_f+0
	lda #>sweep_write_5b
	sta sweep_f+1
	jsr sweep_common
	ldx #$08
	sta $C000
	lda #0
	sta $E000
	rts

sweep_apu:
	lda #<sweep_write_apu
	sta sweep_f+0
	lda #>sweep_write_apu
	sta sweep_f+1
	jsr sweep_common
	lda #0
	sta $4011
	rts

test_registers: ; $20
; not used

test_routines: ; $40
.word init_5b
.word reg
.word sweep_apu
.word sweep_5b
INIT_5B   = $40 ; arg ignored
REG       = $41 ; two byte arg: register, value
SWEEP_APU = $42 ; arg ignored
SWEEP_5B  = $43 ; arg ignored

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte INIT_5B, 0
.byte DELAY, 60
; APU sweep
.byte SWEEP_APU, 0
.byte DELAY, 60
; APU 56Khz 1-bit noise
.byte $0C, $3F ; full constant volume
.byte $0E, $03 ; period 3 (32 cycles)
.byte $0F, $FF ; trigger
.byte DELAY, 180
.byte DELAY, 180
.byte DELAY, 240
.byte $0C, $10 ; 0 volume
.byte DELAY, 60
; 5B sweep
.byte SWEEP_5B, 0
.byte DELAY, 60
; 5B noise
.byte REG, $07, $01 ; 32 cycle noise
.byte REG, $08, $0C ; volume 12
.byte REG, $07, %00110111 ; noise on
.byte DELAY, 180
.byte DELAY, 180
.byte DELAY, 240
.byte REG, $08, $00 ; volume 0
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
