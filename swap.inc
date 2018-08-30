;
; swap.inc
;   useful definitions / access to swap.s
;   https://github.com/bbbradsmith/nes-audio-tests
;

BUZZ     = $60 ; generate buzz (arg: saw ramps / 2)
DELAY    = $61 ; delay by frame count (arg: frames, 0 = 256)
INIT_APU = $62 ; initialize APU (arg: ignored)
LOOP     = $63 ; return to test_data (arg: ignored, unnecessary)

; internal
.global swap_data
.global swap_internal
.global swap

; counted cycle delays (including jsr)
.global swap_delay_frame ; 29780-6 cycles
.global swap_delay_24576
.global swap_delay_12288
.global swap_delay_6144
.global swap_delay_3072
.global swap_delay_1536
.global swap_delay_768
.global swap_delay_384
.global swap_delay_192
.global swap_delay_96
.global swap_delay_48
.global swap_delay_24
.global swap_delay_12

.global swap_delay    ; Y = frames to delay (0 = 256)
.global swap_buzz     ; Y = saw ramps, clobbers A,X, Y
.global swap_init_apu ; INIT_APU, clobbers A,X
.global swap_loop     ; reloads test_data, clobbers A

; zeropage variables
.globalzp read_ptr
.globalzp write_ptr
.globalzp swap_register ; STY abs, RTS
.globalzp swap_internal ; JMP abs

; end of file
