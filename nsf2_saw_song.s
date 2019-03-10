;
; nsf2_saw_song.s
;   NSF2 implementation of Blargg's DMC Saw Wave
;
; Originally written by Blargg, available here:
; http://blargg.8bitalley.com/misc/nes-saw/
;
; Adapted for ca65 and NSF2 by Brad Smith, 2019-3-07
;

.define NSF_TITLE "NSF2 DMC Saw Song"
.define NSF_ARTIST "Blargg/Hip Tanaka/Bach"
.define NSF_COPYRIGHT "2003/1989/1725"
.define NSF_EXPANSION %00000000
.define NSF_REGION    %00000000
.define NSF_VERSION   2
.define NSF2_FLAGS    %00110000

.feature force_range

.segment "ZEROPAGE"

table_entry:    .res 1 ; offset to current saw wave entry for note
table_pos:      .res 1 ; current offset in saw wave table
saw_volume:     .res 1
nmi_count:      .res 1

song_saw_block: .res 1 ; current entry in blocks list
song_saw_tempo: .res 1 ; VBLs per note
song_saw_delay: .res 1 ; VBLs to next note
song_saw_pos:   .res 1 ; offset in sequence data

song_sq_block:  .res 1
song_sq_tempo:  .res 1
song_sq_delay:  .res 1
song_sq_pos:    .res 1

.segment "CODE"

reset:
	; not functional

nsf_init:
	cpy #$81
	beq nsf_init2 ; NSF2 two-stage init
	tya
	pha
	lda #<irq
	sta $FFFE
	lda #>irq
	sta $FFFF

	lda   #$40              ; disable frame IRQ
	sta   $4017
	lda   $4015             ; clear frame IRQ

	lda   #$8E              ; DMC freq + interrupt
	sta   $4010
	lda   # (dpcm_sample - $C000) / 64
	sta   $4012             ; DMC start addr = $FFC0
	lda   #0                ; DMC len
	sta   $4013

	lda   #0
	sta   table_pos
	sta   table_entry

	; start song

	jsr   start_saw
	jsr   start_sq

	lda   #0
	sta   nmi_count

	pla
	cmp #$80
	bne nsf_init2 ; for NSF1 non-returning init hack support
	rts

nsf_init2:

	cli                     ; start DMC
	lda   #$11
	sta   $4015

	; play one tick of song

vbl_loop:0
	lda   nmi_count         ; wait for NMI
:
	cmp   nmi_count
	beq :-
	jsr   do_sq             ; run both voices
	jsr   do_saw
	jmp   vbl_loop


nsf_play: ; previously NMI
	inc   nmi_count         ; just set flag
	rts

nmi: ; not used
	jsr nsf_play
	rti

	; saw-wave (low voice)

do_saw:
	lda   saw_volume        ; volume envelope
	beq   saw_silent
	dec   saw_volume
saw_silent:
	dec   song_saw_delay    ; ready for next note?
	beq   parse_saw
	rts
start_saw:
	lda   #0                ; start at first block
	sta   song_saw_block
next_saw_block:
	ldx   song_saw_block    ; get offset to block data
	inc   song_saw_block
	lda   saw_blocks,x
	beq   start_saw         ; end; repeat blocks
	sta   song_saw_pos
parse_saw:
	ldx   song_saw_pos      ; get next sequence command
	inc   song_saw_pos
	lda   saw_sequence,x
	beq   saw_rest          ; 0: rest
	bpl   saw_note          ; +: MIDI note
	eor   #$80
	beq   next_saw_block    ; $80: end of block
	sta   song_saw_tempo    ; otherwise tempo change
	jmp   parse_saw
saw_note:
	sec
	sbc   #43               ; lowest MIDI note in tables
	tax
	lda   note_offsets,x    ; use new set of DMC periods
	sta   table_entry
	lda   #45               ; reset volume envelope
	sta   saw_volume
saw_rest:
	lda   song_saw_tempo    ; reset next note delay
	sta   song_saw_delay
	rts

	; saw-wave IRQ handler

irq:
	pha                     ; save A and X
	txa
	pha
	ldx   table_pos         ; next period entry
	lda   note_periods,x
	bmi   mid_wave
	lda   saw_volume        ; beginning of new saw
	sta   $4011
	ldx   table_entry
	lda   note_periods,x
	ora   #$80              ; (first entry's high bit isn't set)
mid_wave:
	sta   $4010             ; set DMC period
	inx
	stx   table_pos
	pla                     ; restore X
	tax
	lda   #$11              ; restart DMC as late as possible
	sta   $4015
	pla                     ; restore A
	rti

saw_sequence:

	; each entry contains an optional tempo change followed
	; by a rest or note, or is an end-of-block command.

	; 0         rest note
	; 1-127     MIDI note
	; 128       end of block
	; 129-255   tempo = value - 128

	.byte 255
	; offset = 1
	.byte 140, 54, 0, 66, 0, 65, 0, 54, 0, 57, 0, 61, 0, 66, 0, 62
	.byte 0, 61, 0, 66, 0, 57, 0, 61, 0, 54, 0, 66, 0, 59, 0, 52
	.byte 0, 64, 0, 128
	; offset = 37
	.byte 140, 57, 0, 50, 0, 62, 0, 59, 0, 61, 61, 61, 59, 57, 56, 128
	; offset = 53
	.byte 140, 56, 0, 57, 0, 61, 0, 61, 0, 57, 0, 52, 0, 45, 0, 128
	; offset = 69
	.byte 140, 61, 64, 69, 64, 59, 64, 61, 64, 57, 64, 56, 64, 57, 64, 69
	.byte 64, 59, 64, 61, 64, 57, 64, 56, 64, 57, 61, 57, 54, 66, 63, 60
	.byte 63, 56, 63, 60, 63, 61, 0, 68, 0, 56, 0, 61, 64, 68, 64, 59
	.byte 64, 58, 61, 54, 134, 61, 0, 140, 58, 61, 59, 0, 0, 0, 0, 0
	.byte 60, 63, 56, 134, 63, 0, 140, 60, 63, 61, 0, 0, 0, 0, 0, 61
	.byte 0, 56, 0, 53, 0, 49, 0, 51, 0, 53, 0, 57, 0, 59, 0, 61
	.byte 0, 134, 54, 0, 140, 0, 0, 0, 0, 0, 128

saw_blocks:
	.byte 1, 37, 1, 53, 69, 0

note_offsets:     ; offset into note_periods for a given MIDI note
	.byte $00,$06,$0C,$12,$18,$1E,$23,$29,$2E,$34,$39,$3D,$42,$47,$4D,$53
	.byte $57,$5B,$5F,$63,$67,$6A,$6D,$70,$74,$77,$7B,$7E,$81,$84,$87,$8A
	.byte $8D,$90,$93,$96,$9A,$9D,$A0,$A3,$A6,$A9

note_periods:     ; set of DMC periods for a particular note
                  ; high bit cleared in first entries
	.byte $00,$80,$80,$80,$80,$8A
	.byte $00,$80,$80,$82,$82,$88
	.byte $00,$80,$81,$84,$84,$86
	.byte $00,$80,$80,$81,$8B,$8B
	.byte $00,$80,$80,$86,$89,$8A
	.byte $00,$80,$80,$83,$8C
	.byte $00,$80,$80,$89,$8D,$8D
	.byte $00,$80,$81,$89,$8B
	.byte $00,$80,$82,$8D,$8D,$8E
	.byte $00,$80,$86,$88,$8D
	.byte $00,$80,$82,$8D
	.byte $00,$82,$87,$8A,$8D
	.byte $00,$80,$8B,$8D,$8E
	.byte $00,$86,$89,$8C,$8D,$8E
	.byte $00,$85,$8C,$8D,$8E,$8E
	.byte $00,$83,$8C,$8C
	.byte $00,$88,$89,$8B
	.byte $00,$87,$8B,$8D
	.byte $01,$87,$8B,$8D
	.byte $00,$88,$8E,$8E
	.byte $01,$85,$8D
	.byte $01,$87,$8D
	.byte $00,$8B,$8D
	.byte $03,$8B,$8D,$8E
	.byte $01,$8C,$8D
	.byte $05,$8B,$8D,$8E
	.byte $08,$88,$8B
	.byte $07,$89,$8C
	.byte $06,$8A,$8D
	.byte $07,$8A,$8E
	.byte $06,$8C,$8E
	.byte $08,$8C,$8D
	.byte $08,$8D,$8D
	.byte $0B,$8C,$8C
	.byte $0A,$8C,$8E
	.byte $0D,$8E,$8E,$8E
	.byte $0B,$8D,$8E
	.byte $0B,$8E,$8E
	.byte $0D,$8D,$8D
	.byte $0D,$8D,$8E
	.byte $0D,$8E,$8E
	.byte $0E,$8E,$8E
	.byte $00

	; square (high voice)
	; most comments from saw sequence parser apply here

start_sq:
	lda   #0
	sta   song_sq_block
next_sq_block:
	ldx   song_sq_block
	inc   song_sq_block
	lda   sq_blocks,x
	beq   start_sq
	sta   song_sq_pos
parse_sq:
	ldx   song_sq_pos
	inc   song_sq_pos
	lda   sq_sequence,x
	beq   sq_rest
	bpl   sq_note
	eor   #$80
	beq   next_sq_block
	sta   song_sq_tempo
	jmp   parse_sq
sq_note:
	clc
	adc   #-48
	tax
	lda   #$47
	sta   $4000
	lda   period_l_table,x
	sta   $4002
	lda   period_h_table,x
	ora   #$08
	sta   $4003
sq_rest:
	lda   song_sq_tempo
	sta   song_sq_delay
	rts

do_sq:
	dec   song_sq_delay
	beq   parse_sq
	rts

sq_sequence:
	.byte 255
	; offset = 1
	.byte 140, 69, 73, 78, 73, 68, 73, 69, 73, 66, 73, 65, 73, 69, 73, 78
	.byte 73, 68, 73, 69, 73, 66, 73, 65, 73, 69, 73, 69, 66, 74, 71, 68
	.byte 71, 68, 64, 128
	; offset = 37
	.byte 140, 73, 69, 66, 73, 71, 69, 68, 66, 65, 61, 65, 68, 73, 71, 128
	; offset = 53
	.byte 140, 76, 71, 73, 76, 73, 69, 64, 68, 69, 0, 0, 0, 0, 0, 128
	; offset = 69
	.byte 140, 76, 74, 73, 71, 69, 68, 69, 71, 73, 69, 71, 74, 73, 74, 76
	.byte 0, 68, 0, 69, 71, 73, 0, 71, 0, 73, 0, 78, 0, 75, 0, 78
	.byte 80, 81, 0, 80, 0, 78, 76, 75, 73, 75, 72, 73, 0, 0, 0, 0
	.byte 0, 76, 0, 0, 134, 78, 79, 140, 78, 0, 76, 74, 76, 73, 74, 71
	.byte 78, 0, 0, 134, 80, 81, 140, 80, 0, 78, 77, 78, 75, 77, 73, 80
	.byte 77, 73, 77, 80, 83, 86, 77, 85, 77, 83, 77, 81, 0, 83, 81, 80
	.byte 81, 134, 78, 80, 140, 78, 0, 0, 0, 0, 128

sq_blocks:
	.byte 1, 37, 1, 53, 69, 0

period_h_table:   ; (tuned for NTSC NES hardware)
	.byte 3, 3, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
period_l_table:
	.byte 86, 38, 248, 206, 165, 127, 91, 57, 25, 251, 222, 195
	.byte 170, 146, 123, 102, 82, 63, 45, 28, 12, 253, 238, 225
	.byte 212, 200, 189, 178, 168, 159, 150, 141, 133, 126, 118, 112
	.byte 105, 99, 94, 88, 83, 79, 74, 70, 66, 62, 58, 55

.segment "ALIGN"
.align 64
dpcm_sample:
	.byte 0 ; DPCM sample
.assert dpcm_sample >= $C000, error, "DPCM must be above $C000"

.segment "VECTORS"
	.word  nmi
	.word  reset
	.word  irq

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
.word 16639 ; PAL speed
.byte NSF_REGION ; PAL/NTSC bits
.byte NSF_EXPANSION ; expansion bits
.byte NSF2_FLAGS
NSF_DATA_LEN = (__ROM_BANK_LAST__ - __ROM_BANK_START__) * (__NSFE_SUFFIX_SIZE__ > 0)
.byte <(NSF_DATA_LEN >>  0)
.byte <(NSF_DATA_LEN >>  8)
.byte <(NSF_DATA_LEN >> 16)
.segment "NSFE_SUFFIX"
; empty suffix in case it wasn't already defined
