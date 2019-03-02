REM remove temporary stuff
del build\nsf2_*.o
del build\nsf2_*.nsf
del build\nsf2_*.dbg
del build\nsf2_*.map.txt

cc65\bin\ca65 nsf2_init_play.s    -o build\nsf2_init_play.o    -g
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ca65 nsf2_init_no_play.s -o build\nsf2_init_no_play.o -g
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ca65 nsf2_irq.s          -o build\nsf2_irq.o          -g
@IF ERRORLEVEL 1 GOTO badbuild

cc65\bin\ld65 -o build\nsf2_init_play.nsf    -C nsf2_nsf.cfg build\nsf2_init_play.o    -m build\nsf2_init_play.map.txt    --dbgfile build\nsf2_init_play.dbg
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\nsf2_init_no_play.nsf -C nsf2_nsf.cfg build\nsf2_init_no_play.o -m build\nsf2_init_no_play.map.txt --dbgfile build\nsf2_init_no_play.dbg
@IF ERRORLEVEL 1 GOTO badbuild
cc65\bin\ld65 -o build\nsf2_irq.nsf          -C nsf2_nsf.cfg build\nsf2_irq.o          -m build\nsf2_irq.map.txt          --dbgfile build\nsf2_irq.dbg
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
