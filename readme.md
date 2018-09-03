# nes-audio-tests

Test ROMs and NSFs for NES and Famicom expansion audio. This collection is for testing various details of audio, and verifying emulator implementation. Pre-built ROMs can be found in the build/ folder.

Relative volume tests:
- **db_apu** - Full volume APU square vs. APU triangle.
- **db_vrc6** - Full volume APU square vs. full volume VRC6 square. Hotswap.
- **db_vrc7** - Full volume APU square vs. full volume VRC7 pseudo-square (2:1 modulator at 50%). Hotswap.
- **db_fds** - Full volume APU square vs. full volume FDS square. Hotswap.
- **db_mmc5** - Full volume APU square vs. full volume MMC5 square. Hotswap.
- **db_n163** - Full volume APU square vs. full volume N163 square, 1 channel mode. Hotswap.
- **db_5b** - Full volume APU square vs. volume 12 5B square. Hotswap.

  I am collecting results from these volume tests for a survey. Information is available here:
  - https://forums.nesdev.com/viewtopic.php?t=17741

Hotswap test ROMs are to be loaded on a suitable dev cart. On reset they copy their code to RAM and begin executing there. A buzz will be played through the DMC channel to indicate it is ready, and it will wait ~4 seconds for you to pull out the cartridge, then insert an appropriate expansion audio cartridge. Another buzz will indicate the code is still running before the test begins. After completing the cart will repeat the test. (Hotswapping frequently causes a crash, so it may take multiple attempts.) NROM versions of the hotswap ROMs may be used if the dev cart does not support the original mapper.

Some people are uncomfortable with the idea of hotswapping cartridges. It has been safe in my experience, doing it hundreds of times, but I cannot guarantee it's a 100% safe procedure. All I can say is that it's been worth the risk for me to be able to test these things. Do not hotswap your cartridges if you don't accept this risk.


Other tests: (these are not survey tests, merely part of my personal ongoing investigations)
- **patch_vrc7** - Comparison of prospective VRC7 built-in patch set against the actual set. Hotswap.
- **lfo_vrc7** - Demonstration that the LFO can be reset by flipping bit 7 of $E000 on and off.
- **clip_vrc7** - Demonstration of clipping in the VRC7 amplifier.
- **clip_5b** - Demonstration of ??? in the 5B amplifier (still trying to understand this).


Notes:
- swap.s - common code for hotswap tests

Building:
- Get CC65 and put it in the cc65/ folder. Link: http://cc65.github.io/cc65/
- Use one of the batch files to compile.

License:
- These files may be freely redistributed and modified for any purpose. Credit to the original author and/or a link to the original source would be appreciated, but is not required.
