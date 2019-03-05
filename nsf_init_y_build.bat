REM remove temporary stuff
del build\nsf_init_y.o
del build\nsf_init_y.nsf
del build\nsf_init_y.dbg
del build\nsf_init_y.map.txt

cc65\bin\ca65 nsf_init_y.s -o build\nsf_init_y.o -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\nsf_init_y.nsf -C nsf2_nsf.cfg build\nsf_init_y.o -m build\nsf_init_y.map.txt --dbgfile build\nsf_init_y.dbg
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
