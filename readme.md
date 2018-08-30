# nes-audio-tests

Test ROMs and NSFs for NES and Famicom expansion audio. This collection is for testing various details of audio, and verifying emulator implementation. Pre-built ROMs can be found in the build/ folder.

Hotswap test ROMs are to be loaded as NROM on a suitable dev cart. On reset they copy their code to RAM and begin executing there. A buzz will be played through the DMC channel to indicate it is ready, and it will wait ~4 seconds for you to pull out the cartridge, then insert an appropriate expansion audio cartridge. Another buzz will indicate the code is still running before the test begins. After completing the cart will repeat the test. (Hotswapping frequently causes a crash, so it may take multiple attempts.)

Relative volume tests: (planned)
- db_apu - Full volume APU square vs. full volume DMC PCM.
- db_vrc6 - Full volume APU square vs. full volume VRC6 square. (hotswap)
- db_vrc7 - Full volume APU square vs. full volume VRC7 pseudo-square. (hotswap)
- db_fds - Full volume APU square vs. full volume FDS square.
- db_mmc5 - Full volume APU square vs. full volume MMC5 square. (hotswap)
- db_n163 - Full volume APU square vs. full volume N163 square, 1 channel mode. (hotswap)

Planned tests:
- DAC linearity tests for APU 1&2, all expansions.
- VRC7 patch set test.
- NSFe chunk tests.
- NSF2 functionality tests.


Notes:
- swap.s - common code for hotswap tests

Building:
- Get CC65 and put it in the cc65/ folder. Link: http://cc65.github.io/cc65/
- Use one of the batch files to compile.

License:
- These files may be freely redistributed and modified for any purpose. Credit to the original author and/or a link to the original source would be appreciated, but is not required.