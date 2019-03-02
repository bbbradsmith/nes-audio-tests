;
; nsf2_irq.s
;   verification of NSF2 IRQ feature
;
;   This test is not yet written.
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.define NSF_TITLE "NSF2 INIT PLAY test"
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
.byte "This test is not yet written."
.byte 0
TEXT_LENGTH = *-text_chunk

.segment "ZEROPAGE"


.segment "CODE"
nsf_init:
	rts

nsf_play:
	rts

bad_interrupt:
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
