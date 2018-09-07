REM remove temporary stuff
del build\swap.o
del build\swap_fds.o
del build\db_fds.o
del build\db_fds.fds
del build\db_fds_nrom.nes
del build\db_fds.nsf
del build\db_fds.dbg
del build\db_fds.map.txt

cc65\bin\ca65 swap.s -o build\swap.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 swap_fds.s -o build\swap_fds.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ca65 db_fds.s -o build\db_fds.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_fds_nrom.nes -C swap_nes.cfg build\swap.o build\db_fds.o -m build\db_fds_nrom.map.txt --dbgfile build\db_fds_nrom.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_fds.fds      -C swap_fds.cfg build\swap.o build\db_fds.o build\swap_fds.o -m build\db_fds.map.txt --dbgfile build\db_fds.dbg
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\db_fds.nsf      -C swap_nsf.cfg build\swap.o build\db_fds.o
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
