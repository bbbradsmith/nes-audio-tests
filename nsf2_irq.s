;
; nsf2_irq.s
;   verification of NSF2 IRQ feature
;
;   1. INIT will be called once.
;      INIT will set up the NSF2 IRQ timer and enable it.
;      INIT will return (and won't be called again, this is not a non-returning INIT).
;   2. The IRQ timer should begin playing a square wave tone on $4011 at 450Hz.
;   3. PLAY will be called at its specified rate.
;      Every 60 plays, PLAY will alter the IRQ timer frequency to play an 8 step sequence.
;      PLAY will delay ~13000 cycles before returning to demonstrate that it is not blocking the IRQ.
;      (If the non-returning INIT feature was used, PLAY would instead
;       enter with the I flag set, as it would be from within an NMI response.)
;
;   Verify:
;     - No sound will be heard unless the IRQ feature it working properly.
;     - If the IRQ vector RAM overlay at $FFFE is not present,
;       a triangle tone of 1100Hz will play.
;     - The IRQ will generate a square wave at 450Hz for one second before
;       the PLAY routine starts to change it to a repeating 8 tone melody,
;       once per second.
;     - PLAY should not block IRQs. It executes for about half of each frame,
;       which will impose a strong 60Hz buzz if it is blocking.
;       (When we are not using non-returning INIT, PLAY has no implied SEI.)
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.define NSF_TITLE "NSF2 IRQ test"
.define NSF_ARTIST "Brad Smith"
.define NSF_COPYRIGHT "2019 nes-audio-tests"
.define NSF_EXPANSION %00000000
.define NSF_REGION    %00000010
.define NSF_VERSION   2
.define NSF2_FLAGS    %00010000

.segment "NSFE_SUFFIX"
.dword TEXT_LENGTH
.byte "text"
text_chunk:
.define NL 13,10
.byte ";   verification of NSF2 IRQ feature",NL
.byte ";",NL
.byte ";   1. INIT will be called once.",NL
.byte ";      INIT will set up the NSF2 IRQ timer and enable it.",NL
.byte ";      INIT will return (and won't be called again, this is not a non-returning INIT).",NL
.byte ";   2. The IRQ timer should begin playing a square wave tone on $4011 at 450Hz.",NL
.byte ";   3. PLAY will be called at its specified rate.",NL
.byte ";      Every 60 plays, PLAY will alter the IRQ timer frequency to play an 8 step sequence.",NL
.byte ";      PLAY will delay ~13000 cycles before returning to demonstrate that it is not blocking the IRQ.",NL
.byte ";      (If the non-returning INIT feature was used, PLAY would instead",NL
.byte ";       enter with the I flag set, as it would be from within an NMI response.)",NL
.byte ";",NL
.byte ";   Verify:",NL
.byte ";     - No sound will be heard unless the IRQ feature it working properly.",NL
.byte ";     - If the IRQ vector RAM overlay at $FFFE is not present,",NL
.byte ";       a triangle tone of 1100Hz will play.",NL
.byte ";     - The IRQ will generate a square wave at 450Hz for one second before",NL
.byte ";       the PLAY routine starts to change it to a repeating 8 tone melody,",NL
.byte ";       once per second.",NL
.byte ";     - PLAY should not block IRQs. It executes for about half of each frame,",NL
.byte ";       which will impose a strong 60Hz buzz if it is blocking.",NL
.byte ";       (When we are not using non-returning INIT, PLAY has no implied SEI.)",NL
.byte ";",NL
.byte ";   https://github.com/bbbradsmith/nes-audio-tests.byte 0",NL
TEXT_LENGTH = *-text_chunk

.segment "ZEROPAGE"
irq_flip: .res 1
play_count: .res 1
song_position: .res 1

.segment "CODE"

BAD_TONE = (1789772 / (1100*32)) - 1 ; 1100Hz triangle

; some just musical tones for the IRQ timer based on C5=240Hz
C5 = (1789772 / (240 * 2)) - 1
D5 = (1789772 / (270 * 2)) - 1
E5 = (1789772 / (300 * 2)) - 1
F5 = (1789772 / (320 * 2)) - 1
G5 = (1789772 / (360 * 2)) - 1
A5 = (1789772 / (400 * 2)) - 1
B5 = (1789772 / (450 * 2)) - 1
F4 = (1789772 / (160 * 2)) - 1
G4 = (1789772 / (180 * 2)) - 1

; 8 tone song
song:
.word C5, D5, E5, G4, G5, A5, F5, F4

; starting note to test PLAY not working
START_NOTE = B5

nsf_init:
	; reset IRQ
	sei
	lda #0
	sta $401D
	; setup IRQ pointer
	lda #<irq
	sta $FFFE
	lda #>irq
	sta $FFFF
	; set starting frequency
	lda #<START_NOTE
	sta $401B
	lda #>START_NOTE
	sta $401C
	; begin IRQ
	lda #1
	sta $401D
	cli
	rts

delay12288: jsr delay6144
delay6144:  jsr delay3072
delay3072:  jsr delay1536
delay1536:  jsr delay768
delay768:   jsr delay384
delay384:   jsr delay192
delay192:   jsr delay96
delay96:    jsr delay48
delay48:    jsr delay24
delay24:    jsr delay12
delay12:    rts

nsf_play:
	inc play_count
	lda play_count
	cmp #60
	bcc @delay
	lda #0
	sta play_count
	; set the IRQ length for next note
	ldx song_position
	lda song+0, X
	sta $401B
	lda song+1, X
	sta $401C
	inx
	inx
	txa
	and #7
	sta song_position
@delay:
	; half a frame of busy-waiting just to verify it's not interfering with IRQ
	jsr delay12288
	rts

irq:
	pha
	; generates a $4011 square wave at half its interrupt frequency
	lda irq_flip
	eor #$1F
	sta irq_flip
	sta $4011
	lda $401D ; acknowledge IRQ
	pla
	rti

bad_interrupt:
	pha
	; bad interrupt will play the triangle channel
	lda #$FF
	sta $4008
	lda # <BAD_TONE
	sta $400A
	lda # >BAD_TONE | $F8
	sta $400B
	pla
	rti

; Explicitly placing an "error" bad interrupt in the NSF's vector table area as a test.
; The NSF2 compliant player should overlay the 6 vector bytes.
; and allow $FFFE/$FFFF to be written as RAM by the NSF code.
.segment "VECTORS"
.word bad_interrupt
.word bad_interrupt
.word bad_interrupt

; NSF header
.import __ROM_BANK_START__
.import __ROM_BANK_LAST__
.import __NSFE_SUFFIX_SIZE__
.segment "NSF_HEADER"
.byte 'N', 'E', 'S', 'M', $1A ; ID
.byte NSF_VERSION
.byte 1 ; songs
.byte 1 ; starting song
.word __ROM_BANK_START__ ; LOAD
.word nsf_init ; INIT
.word nsf_play ; PLAY
.byte NSF_TITLE
.res 32 - .strlen(NSF_TITLE)
.byte NSF_ARTIST
.res 32 - .strlen(NSF_ARTIST)
.byte NSF_COPYRIGHT
.res 32 - .strlen(NSF_COPYRIGHT)
.assert * = $6E, error, "NSF strings may be too long?"
.word 16639 ; NTSC speed
.byte 0,0,0,0,0,0,0,0
.word 19997 ; PAL speed
.byte NSF_REGION ; PAL/NTSC bits
.byte NSF_EXPANSION ; expansion bits
.byte NSF2_FLAGS
NSF_DATA_LEN = (__ROM_BANK_LAST__ - __ROM_BANK_START__) * (__NSFE_SUFFIX_SIZE__ > 0)
.byte <(NSF_DATA_LEN >>  0)
.byte <(NSF_DATA_LEN >>  8)
.byte <(NSF_DATA_LEN >> 16)
.segment "NSFE_SUFFIX"
; empty suffix in case it wasn't already defined
