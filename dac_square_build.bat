REM remove temporary stuff
del build\swap.o
del build\dac_square.o
del build\dac_square.nes
del build\dac_square.nsf
del build\dac_square.dbg
del build\dac_square.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 dac_square.s -o build\dac_square.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\dac_square.nes -C swap_nes.cfg build\swap.o build\dac_square.o -m build\dac_square.map.txt --dbgfile build\dac_square.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\dac_square.nsf -C swap_nsf.cfg build\swap.o build\dac_square.o
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
