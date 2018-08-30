REM remove temporary stuff
del out_build\swap.o
del out_build\db_5b.o
del out_build\db_5b.nes
del out_build\db_5b.nsf
del out_build\db_5b.dbg
del out_build\db_5b.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_5b.s -o build\db_5b.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_5b.nes -C swap_nes.cfg -m build\db_5b.map.txt --dbgfile build\db_5b.dbg   build\swap.o build\db_5b.o
@IF ERRORLEVEL 1 GOTO badbuild

REM cc65\bin\ld65 -o build\db_5b.nsf -C swap_nsf.cfg                                                    build\swap.o out_build\db_5b.o
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
