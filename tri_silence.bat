REM remove temporary stuff
del build\swap.o
del build\tri_silence.o
del build\tri_silence.nes
del build\tri_silence.nsf
del build\tri_silence.dbg
del build\tri_silence.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 tri_silence.s -o build\tri_silence.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\tri_silence.nes -C swap_nes.cfg build\swap.o build\tri_silence.o -m build\tri_silence.map.txt --dbgfile build\tri_silence.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\tri_silence.nsf -C swap_nsf.cfg build\swap.o build\tri_silence.o
@IF ERRORLEVEL 1 GOTO badbuild

@echo.
@echo.
@echo Build complete and successful!
@IF NOT "%1"=="" GOTO endbuild
@pause
@GOTO endbuild

:badbuild
@echo.
@echo.
@echo Build error!
@IF NOT "%1"=="" GOTO endbuild
@pause
:endbuild
