REM remove temporary stuff
del build\swap.o
del build\db_mmc5.o
del build\db_mmc5.nes
del build\db_mmc5_nrom.nes
del build\db_mmc5.nsf
del build\db_mmc5.dbg
del build\db_mmc5.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_mmc5.s -o build\db_mmc5.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_mmc5.nes      -C swap_nes.cfg build\swap.o build\db_mmc5.o -D INES_MAPPER=5 -m build\db_mmc5.map.txt --dbgfile build\db_mmc5.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_mmc5_nrom.nes -C swap_nes.cfg build\swap.o build\db_mmc5.o
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_mmc5.nsf      -C swap_nsf.cfg build\swap.o build\db_mmc5.o
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
