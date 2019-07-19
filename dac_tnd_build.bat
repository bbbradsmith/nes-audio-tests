REM remove temporary stuff
del build\swap.o
del build\dac_tnd_common.o
del build\dac_tnd*.o
del build\dac_tnd*.nes
del build\dac_tnd*.nsf
del build\dac_tnd*.dbg
del build\dac_tnd*.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 dac_tnd_common.s -o build\dac_tnd_common.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 dac_tnd0.s -o build\dac_tnd0.o -g
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ca65 dac_tnd1.s -o build\dac_tnd1.o -g
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ca65 dac_tnd2.s -o build\dac_tnd2.o -g
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ca65 dac_tnd3.s -o build\dac_tnd3.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\dac_tnd0.nes -C swap_nes.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd0.o -m build\dac_tnd0.map.txt --dbgfile build\dac_tnd0.dbg
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\dac_tnd1.nes -C swap_nes.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd1.o -m build\dac_tnd1.map.txt --dbgfile build\dac_tnd1.dbg
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\dac_tnd2.nes -C swap_nes.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd2.o -m build\dac_tnd2.map.txt --dbgfile build\dac_tnd2.dbg
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\dac_tnd3.nes -C swap_nes.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd3.o -m build\dac_tnd3.map.txt --dbgfile build\dac_tnd3.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\dac_tnd0.nsf -C swap_nsf.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd0.o
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\dac_tnd1.nsf -C swap_nsf.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd1.o
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\dac_tnd2.nsf -C swap_nsf.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd2.o
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\dac_tnd3.nsf -C swap_nsf.cfg build\swap.o build\dac_tnd_common.o build\dac_tnd3.o
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
