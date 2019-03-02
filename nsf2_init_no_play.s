;
; nsf2_init_no_play.s
;   verification of NSF2 non-returning INIT and PLAY suppression feature
;
;   1. INIT should be called once and let return.
;   2. After INIT first returns, PLAY should _not_ be enabled.
;   3. INIT will be called again and is allowed to enter an infinite loop.
;   4. PLAY will _not_ interrupt the non-returned INIT loop.
;
;   Verify:
;     When INIT is called a second time, it plays a 250Hz 0-duty square wave tone.
;     If PLAY is called regularly it plays a 100Hz square wave through $4011.
;     The result should hear only the INIT tone.
;
;     An error tone of 1100Hz will be played by the triangle in response
;     to an unexpected NMI or IRQ fetching from the NSF's vector area,
;     which should have been replaced and controlled by the NSF2 player's overlay.
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.define NSF_TITLE "NSF2 INIT no PLAY test"
.define NSF_ARTIST "Brad Smith"
.define NSF_COPYRIGHT "2019 nes-audio-tests"
.define NSF_EXPANSION %00000000
.define NSF_REGION    %00000010
.define NSF_VERSION   2
.define NSF2_FLAGS    %01100000

.segment "NSFE_SUFFIX"
.dword TEXT_LENGTH
.byte "text"
text_chunk:
.define NL 13,10
.byte ";   verification of NSF2 non-returning INIT and PLAY suppression feature",NL
.byte ";",NL
.byte ";   1. INIT should be called once and let return.",NL
.byte ";   2. After INIT first returns, PLAY should _not_ be enabled.",NL
.byte ";   3. INIT will be called again and is allowed to enter an infinite loop.",NL
.byte ";   4. PLAY will _not_ interrupt the non-returned INIT loop.",NL
.byte ";",NL
.byte ";   Verify:",NL
.byte ";     When INIT is called a second time, it plays a 250Hz 0-duty square wave tone.",NL
.byte ";     If PLAY is called regularly it plays a 100Hz square wave through $4011.",NL
.byte ";     The result should hear only the INIT tone.",NL
.byte ";",NL
.byte ";     An error tone of 1100Hz will be played by the triangle in response",NL
.byte ";     to an unexpected NMI or IRQ fetching from the NSF's vector area,",NL
.byte ";     which should have been replaced and controlled by the NSF2 player's overlay.",NL
.byte ";",NL
.byte ";   https://github.com/bbbradsmith/nes-audio-tests",NL
.byte 0
TEXT_LENGTH = *-text_chunk

.segment "ZEROPAGE"
init_count: .res 1
play_flip: .res 1

.segment "CODE"

PLAY_TONE = (1000000 / (100*2))      ; 100Hz $4011 square
INIT_TONE = (1789772 / (250*16)) - 1 ; 250Hz duty-0 APU square
BAD_TONE = (1789772 / (1100*32)) - 1 ; 1100Hz triangle

nsf_init:
	inc init_count
	lda init_count
	cmp #2
	bcs :+
		; first time INIT will return
		rts
	:
	; second time INIT will play the square channel and enter an infinite loop
	lda #%00111111 ; duty 0, constant full volume
	sta $4000
	lda # <INIT_TONE
	sta $4002
	lda # >INIT_TONE | $F8
	sta $4003
init_loop:
	rts

nsf_play:
	; play generates a 30Hz square wave
	lda play_flip
	eor #$1F
	sta play_flip
	sta $4011
	rts

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
;.word 16639 ; NTSC speed
.word PLAY_TONE
.byte 0,0,0,0,0,0,0,0
;.word 19997 ; PAL speed
.word PLAY_TONE
.byte NSF_REGION ; PAL/NTSC bits
.byte NSF_EXPANSION ; expansion bits
.byte NSF2_FLAGS
NSF_DATA_LEN = (__ROM_BANK_LAST__ - __ROM_BANK_START__) * (__NSFE_SUFFIX_SIZE__ > 0)
.byte <(NSF_DATA_LEN >>  0)
.byte <(NSF_DATA_LEN >>  8)
.byte <(NSF_DATA_LEN >> 16)
.segment "NSFE_SUFFIX"
; empty suffix in case it wasn't already defined

