REM remove temporary stuff
del build\swap.o
del build\db_apu.o
del build\db_apu.nes
del build\db_apu.nsf
del build\db_apu.dbg
del build\db_apu.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_apu.s -o build\db_apu.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_apu.nes -C swap_nes.cfg build\swap.o build\db_apu.o -m build\db_apu.map.txt --dbgfile build\db_apu.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_apu.nsf -C swap_nsf.cfg build\swap.o build\db_apu.o
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
