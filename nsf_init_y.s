;
; nsf_init_y.s
;   test of Y register value on enter to INIT
;
;   produces a repeating series of 8 beeps indicating the value of Y on INIT
;   MSB first
;   300Hz high tone, duty 2 = 1
;   100Hz low tone, duty 0 = 0
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

.define NSF_TITLE "NSF INIT Y test"
.define NSF_ARTIST "Brad Smith"
.define NSF_COPYRIGHT "2019 nes-audio-tests"
.define NSF_EXPANSION %00000000
.define NSF_REGION    %00000010
.define NSF_VERSION   1
.define NSF2_FLAGS    %00000000

.segment "NSFE_SUFFIX"
.dword TEXT_LENGTH
.byte "text"
text_chunk:
.define NL 13,10
.byte ";   test of Y register value on enter to INIT",NL
.byte ";",NL
.byte ";   produces a repeating series of 8 beeps indicating the value of Y on INIT",NL
.byte ";   MSB first",NL
.byte ";   300Hz high tone, duty 2 = 1",NL
.byte ";   100Hz low tone, duty 0 = 0",NL
.byte ";",NL
.byte ";   https://github.com/bbbradsmith/nes-audio-tests",NL
TEXT_LENGTH = *-text_chunk

.segment "ZEROPAGE"
stored_y: .res 1
bits_shift: .res 1
sequence: .res 1
frames_remain: .res 1

.segment "CODE"

BIT_TIME = 5
SPACE_TIME = 5
END_TIME = 90

TONE1 = (1789772 / (300*16)) - 1 ; 300Hz square
TONE0 = (1789772 / (100*16)) - 1 ; 100Hz square

play_1:
	lda #%10111111 ; duty 2, constant full volume
	sta $4000
	lda # <TONE1
	sta $4002
	lda # >TONE1 | $F8
	sta $4003
	rts

play_0:
	lda #%00111111 ; duty 0, constant full volume
	sta $4000
	lda # <TONE0
	sta $4002
	lda # >TONE0 | $F8
	sta $4003
	rts

play_off:
	lda #%00110000 ; constant volume 0
	sta $4000
	rts

play_bit:
	lda #BIT_TIME
	sta frames_remain
	asl bits_shift
	bcs :+
		jmp play_0
	:
		jmp play_1

nsf_init:
	sty stored_y
	sty bits_shift
	lda #$7F
	sta $4001 ; diable sweep muting for low frequencies
	rts

nsf_play:
	lda frames_remain
	beq :+
		dec frames_remain
		rts
	:
	lda sequence
	inc sequence
	cmp #16
	bcs @sequence_end
	and #1
	bne @sequence_space
@sequence_bit:
	jmp play_bit
@sequence_space:
	lda #SPACE_TIME
	sta frames_remain
	jmp play_off
@sequence_end:
	lda #0
	sta sequence
	lda #END_TIME
	sta frames_remain
	lda stored_y
	sta bits_shift
	jmp play_off

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
