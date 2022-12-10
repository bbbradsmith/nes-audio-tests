REM remove temporary stuff
del build\swap.o
del build\test_n163_longwave.o
del build\test_n163_longwave.nes
del build\test_n163_longwave_nrom.nes
del build\test_n163_longwave.nsf
del build\test_n163_longwave.dbg
del build\test_n163_longwave.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 test_n163_longwave.s -o build\test_n163_longwave.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\test_n163_longwave.nes      -C swap_nes.cfg build\swap.o build\test_n163_longwave.o -D INES_MAPPER=19 -m build\test_n163_longwave.map.txt --dbgfile build\test_n163_longwave.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\test_n163_longwave_nrom.nes -C swap_nes.cfg build\swap.o build\test_n163_longwave.o
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\test_n163_longwave.nsf      -C swap_nsf.cfg build\swap.o build\test_n163_longwave.o
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
