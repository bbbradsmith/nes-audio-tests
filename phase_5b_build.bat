REM remove temporary stuff
del build\swap.o
del build\phase_5b.o
del build\phase_5b.nes
del build\phase_5b_nrom.nes
del build\phase_5b.nsf
del build\phase_5b.dbg
del build\phase_5b.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 phase_5b.s -o build\phase_5b.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\phase_5b.nes      -C swap_nes.cfg build\swap.o build\phase_5b.o -D INES_MAPPER=69 -m build\phase_5b.map.txt --dbgfile build\phase_5b.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\phase_5b_nrom.nes -C swap_nes.cfg build\swap.o build\phase_5b.o
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\phase_5b.nsf      -C swap_nsf.cfg build\swap.o build\phase_5b.o
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
