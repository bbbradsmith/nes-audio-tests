;
; swap.inc
;   useful definitions / access to swap.s
;   https://github.com/bbbradsmith/nes-audio-tests
;

;
; Creating a test:
;
; 1. Define and export:
;   test_registers
;   test_routines
;   test_data
;   INES_MAPPER (optional)
;   INES2_REGION (optional)
;   NSF_EXPANSION (optional)
;   SKIP_HOTSWAP (optional)
; 2. Use NSF_STRINGS to set up the NSF header.
;
; test_data is a list of text commands to be executed in sequence.
; Most commands are 2 bytes long: 1-byte command, then 1-byte argument.
; test_data should end with LOOP to restart the test.
; test_data may optionally begin with "BUZZ, 50" to mark the start of the test.
;
; Commands:
;   $00-$1F - writes argument to APU register $4000+command
;   $20-$3F - writes argument to test_registers location
;   $40-$5F - calls subroutine from test_routines with argument in Y
;   $60-$7F - built=in routines (BUZZ, DELAY, INIT_APU, LOOP, see below)
;
; test_registers is a list of up to 32 16-bit addresses that can
; directly receive an argument.
;
; test_routines is a list of up to 32 16-bit subroutines that can
; be called with Y containing the argument.
; The subroutine may read additional bytes from (read_ptr) and increment it
; if additional arguments are needed.
;
; INES_MAPPER = mapper number for .NES version. (0 if omitted.)
;
; INES2_REGION = 0 NTSC, 1 PAL, 2 Dual. (2 if omitted.)
;
; NSF_EXPANSION = NSF expansion audio bitfield, 0 = none. (0 if omitted.)
;
; SKIP_HOTSWAP = 0 to begin with a hotswap, 1 to skip this
; A hotswap test will begin with a short buzz, then a 5 second wait before beginning.
; If hotswapping, place the entire test in the SWAP segment. (1 if omitted.)
;
; NSF_STRINGS "title", "artist", "copyright"
;
; Segments:
;   ZEROPAGE - Variables, initialized to 0.
;   STACK    - If needed, a few bytes can be reserved here for variables.
;   RAM      - Variables, initialized to 0.
;   SWAP     - All hotswap code. Must fit within the built-in RAM of the NES.
;   SHARED   - Non-hotswapped code.
;   NES      - Non-hotswapped code, .NES-only.
;   NSF      - Non-hotswapped code, .NSF-only.
;
; For cycle-timed code there are some pre-made delay routines available, see below.
;

; built-in test commands

BUZZ     = $60 ; generate buzz (arg: saw ramps / 2)
DELAY    = $61 ; delay by frame count (arg: frames, 0 = 256)
INIT_APU = $62 ; initialize APU (arg: ignored)
LOOP     = $63 ; return to test_data (arg: ignored, unnecessary)

; strings macro for NSF header

.macro NSF_STRINGS title_, artist_, copyright_
	.segment "NSF_HEADER1"
	.byte title_
	.res 32 - .strlen(title_)
	.byte artist_
	.res 32 - .strlen(artist_)
	.byte copyright_
	.res 32 - .strlen(copyright_)
	.assert * = $6E, error, "NSF_STRINGS too long?"
.endmacro

; counted cycle delays (including jsr)

.global swap_delay_frame ; 29774 cycles (approximate NTSC frame -6 cy)
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
.globalzp swap_routine ; JMP abs

; end of file
