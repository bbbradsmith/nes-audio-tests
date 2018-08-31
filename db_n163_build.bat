REM remove temporary stuff
del out_build\swap.o
del out_build\db_n163.o
del out_build\db_n163.nes
del out_build\db_n163_nrom.nes
del out_build\db_n163.nsf
del out_build\db_n163.dbg
del out_build\db_n163.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_n163.s -o build\db_n163.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_n163.nes      -C swap_nes.cfg build\swap.o build\db_n163.o -D INES_MAPPER=19 -m build\db_n163.map.txt --dbgfile build\db_n163.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_n163_nrom.nes -C swap_nes.cfg build\swap.o build\db_n163.o
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_n163.nsf      -C swap_nsf.cfg build\swap.o build\db_n163.o
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
