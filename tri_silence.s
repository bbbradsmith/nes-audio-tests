;
; tri_silent.s
;   Testing methods of silencing the triangle
;   and interaction between $4008/$400B and the linear counter
;
;   https://github.com/bbbradsmith/nes-audio-tests
;

; each line lasts 1 second:
; 1 tone
;   halt by $4008 alone, 1/4 frame delay
; 2 tone
;   halt by $4008 alone, immediate
; 3 tone woken by $4008 alone
;   halt
; 4 tone woken by $4008/$400B
;   halt
; 5 tone
;   halt by $4008, $400B, 1/4 frame delay
; 6 tone
;   halt by $4008, $400B, immediate
; 7 tone
;   halt by $4015
;   resume by $4015 (no tone)
;   tone by $400B length counter wake
;   halt
; 8 tone
;   ultrasonic silence
;   tone
;   silence
; 9 tone
;   silence by $00 to $4008
;   tone
;   silence by $00 to $4008/$400B
;10 tone 1/2 second (silenced by linear counter expiry)
;   silence
;   tone by $400B refresh of linear counter, 1/2 second
;   silence
;11 tone (1/2 second)
;   silence (ignores intervening $4008 write that would extend tone)
;   tone (1/2 second, ignores intervening $4008 write that would shorten it)
;   silence
;   silence (wakeup by $4008 alone fails, reload not currently set)
;   tone (wakeup by $400B, reload flag is held)
;   silence (silenced by $4008 alone because of reload flag still set, linear counter halted)
;   tone 1/2 second (demonstrates $4008 without high bit can wakeup if in halt+reload state)
;   silence
;   tone 1/2 second (woken by $400B)
;   silence

.include "swap.inc"

NSF_STRINGS "tri_silence test", "Brad Smith", "2019 nes-audio-tests"
NSF_EXPANSION = %00000000
SKIP_HOTSWAP = 1

.export test_registers
.export test_routines
.export test_data
.exportzp SKIP_HOTSWAP
.exportzp NSF_EXPANSION

.segment "SWAP"

test_registers: ; $20
; not used

test_routines: ; $40
; not used

test_data:
.byte BUZZ, 50
.byte INIT_APU, 0
.byte DELAY, 60

; APU 440Hz triangle, silenced with just a write to $4008
.byte $08, $FF ; halt counter
.byte $0A, 126 ; (126+1)*32 = 4064 cycle triangle = ~440.40Hz
.byte $0B, $F0 ; begin
.byte DELAY, 60
.byte $17, $C0
.byte $08, $80 ; silence (should be delayed 1/4 frame)
.byte DELAY, 60
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $08, $80
.byte $17, $C0 ; silence (should be immediate)
.byte DELAY, 60

; silenced triangle will be woken by $4008 alone
.byte $08, $FF
.byte DELAY, 60
.byte $08, $80
.byte DELAY, 60

; silenced triangle will be woken by $4008 + $400B
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $08, $80
.byte DELAY, 60

; silenced with a write to $4008, 400B
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 69
.byte $17, $C0 ; 1/4 frame delay
.byte $08, $80
.byte $0B, $F0
.byte DELAY, 60
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $08, $80
.byte $0B, $F0
.byte $17, $C0 ; immediate
.byte DELAY, 60

; verify that linear counter is not affected by $4015
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $15, $00 ; sound off
.byte DELAY, 60
.byte $15, $0F ; $4015 on but length counter still 0
.byte DELAY, 60
.byte $0B, $F0 ; sound on: length counter reloaded, linear counter remains at $7F
.byte DELAY, 60
.byte $08, $80 ; silence
.byte DELAY, 60

; silence by ultrasonic frequency
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $0A, $00 ; "silence" by ultrasonic frequency
.byte DELAY, 60
.byte $0A, 126 ; A440
.byte DELAY, 60
.byte $08, $80 ; silence
.byte DELAY, 60

; silence by $00 to $4008
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $08, $00
.byte DELAY, 60
; silence by $00 to $4008 followed by refresh of $400B
.byte $08, $FF
.byte $0B, $F0
.byte DELAY, 60
.byte $08, $00
.byte $0B, $F0
.byte DELAY, 60

; verify that $400B can reload $4008
.byte $08, 124 ; will last 31 frames if left alone
.byte $0B, $F0
.byte DELAY, 120
.byte $0B, $F0 ; will cause linear counter to reload to 124 again
.byte DELAY, 120

; verify that $4008 won't reload on its own when linear counter isn't halted
.byte $0B, $F0 ; wake the triangle with reload of 124 (31 frames)
.byte DELAY, 15
.byte $08, 124 ; note that this does not extend the envelope
.byte DELAY, 105
.byte $0B, $F0 ; wake the triangle with 124
.byte DELAY, 15
.byte $08, $00 ; note that 0 does not silence the triangle early here
.byte DELAY, 105
.byte $08, $FF ; note that this doesn't wake the triangle (halted but not in reload)
.byte DELAY, 60
.byte $0B, $F0 ; sets reload, wakes triangle
.byte DELAY, 60
.byte $08, $80 ; note that this silences the triangle (reload still set)
.byte DELAY, 60
.byte $08, 124 ; note that this wakes the triangle
.byte DELAY, 120
.byte $0B, $F0 ; wake the triangle
.byte DELAY, 120

.byte LOOP

; end of file
