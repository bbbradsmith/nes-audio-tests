REM remove temporary stuff
del out_build\swap.o
del out_build\db_vrc6.o
del out_build\db_vrc6.nes
del out_build\db_vrc6_nrom.nes
del out_build\db_vrc6.nsf
del out_build\db_vrc6.dbg
del out_build\db_vrc6.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_vrc6.s -o build\db_vrc6.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6.nes      -C swap_nes.cfg build\swap.o build\db_vrc6.o -D INES_MAPPER=24 -m build\db_vrc6.map.txt --dbgfile build\db_vrc6.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6_nrom.nes -C swap_nes.cfg build\swap.o build\db_vrc6.o
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6.nsf      -C swap_nsf.cfg build\swap.o build\db_vrc6.o
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
