REM remove temporary stuff
del out_build\swap.o
del out_build\db_vrc6.o
del out_build\db_vrc6a.nes
del out_build\db_vrc6a_nrom.nes
del out_build\db_vrc6b.nes
del out_build\db_vrc6b_nrom.nes
del out_build\db_vrc6.nsf
del out_build\db_vrc6a.dbg
del out_build\db_vrc6a.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_vrc6.s -o build\db_vrc6.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6a.nes      -C swap_nes.cfg build\swap.o build\db_vrc6.o -D INES_MAPPER=24 -D VRC6A=1 -m build\db_vrc6a.map.txt --dbgfile build\db_vrc6a.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6b.nes      -C swap_nes.cfg build\swap.o build\db_vrc6.o -D INES_MAPPER=26 -D VRC6A=0
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6a_nrom.nes -C swap_nes.cfg build\swap.o build\db_vrc6.o -D VRC6A=1
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6b_nrom.nes -C swap_nes.cfg build\swap.o build\db_vrc6.o -D VRC6A=0
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_vrc6.nsf       -C swap_nsf.cfg build\swap.o build\db_vrc6.o -D VRC6A=1
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
