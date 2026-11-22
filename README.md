# Osborne 1 for MiSTer

*[Leer en español](README_es.md) — the Spanish README has the full documentation
and development notes.*

An FPGA implementation of the **Osborne 1** (1981), the first commercially
successful portable computer, for the **MiSTer** platform. It runs the original
BIOS ROM 1.44 and boots CP/M 2.2 from single and double density disk images.

This repository started as a fork of
[jackpot51/Osborne_MiSTer](https://github.com/jackpot51/Osborne_MiSTer) by
Jeremy Soller, who started the project (CPU, ROMs and text video); his commits
are kept in the history. That core did not get past the start-up screen: there
was no disk controller, no PIAs, no interrupts and the memory banking was
incomplete. The machine has been rewritten
following the Osborne 1 Technical Manual and the MAME `osborne1` driver.

## Features

- Z80 at 3.9936 MHz (T80) with clock enables from a 31.94 MHz system clock.
- 64 KB RAM, BIOS ROM 1.44 and the 7A3007-00 character generator.
- **Memory banking** as on the real board: ROM/RAM mode (I/O ports 0/1), BIT 9
  attribute RAM (ports 2/3) and the UB4A/UB6A flip-flops that force ROM mode on
  interrupt acknowledge and on the front panel RESET (NMI).
- **Interrupt mode 2** with the original vectors (IEEE PIA F0h, video PIA F8h,
  ACIA FCh).
- **Video**: 52 x 24 window over the 128 x 32 virtual screen, hardware
  horizontal and vertical scroll, half intensity, underline and block
  graphics. 15.6 kHz / 60 Hz, green, amber or white phosphor.
- **SCREEN-PAC** (OSD option): Osborne's 104 column board. The CP/M SETUP
  program detects it and offers 52, 80 or 104 physical columns. The video
  output keeps the same timing in both modes, so the scaler never loses sync.
- Two **MC6821 PIAs** (video/disk control and IEEE-488).
- **WD1793/MB8877 floppy controller**, two drives, read and write. Single
  density (100 KB) and double density (200 KB) images; the BIOS detects the
  density by itself, as on real hardware.
- **Serial port**: MC6850 ACIA with the board's baud rate clock (300/1200,
  600/2400, 1200/4800 or 2400/9600 jumper settings), interrupts and modem
  lines, connected to the MiSTer UART.
- Keyboard matrix from PS/2 and the beeper.
- Verilator testbench that boots CP/M with real disk images.

Not implemented: IEEE-488 devices and the Nuevo Video 80 column board.

## Quick start

1. Copy `releases/Osborne_YYYYMMDD.rbf` to `_Computer/` on the SD card.
2. Put raw disk images (`.IMG`/`.DSK`, 102400 or 204800 bytes) in
   `games/Osborne`. ImageDisk files can be converted with
   `python3 tools/imd2img.py disk.imd disk.img`.
3. Mount a CP/M system disk as Drive A: and press **Enter** at the prompt.

**F10** is the front panel RESET button. Backspace is cursor left and Caps Lock
is ALPHA LOCK.

**Serial port**: choose the speed pair in the OSD (the Osborne jumpers; the
software selects low or high speed) and set the same speed in the MiSTer UART
menu. In CP/M, `STAT CON:=CRT:` moves the console to the serial port;
`RDR:=PTR:` and `PUN:=PTP:` are the serial reader and punch. See the Spanish
README for details.

**SCREEN-PAC**: enable it in the OSD and boot a CP/M disk whose BIOS supports
it (for example the Osborne extended utilities disk). Run `SETUP`, choose
*C Screen size*, then the physical width, and save to memory or disk.

**Disk images and ROM dumps of software are not included**, except the BIOS
and character ROMs already present in the original repository.

## Chameleon96

The Chameleon96 version lives in
[shaeon/Osborne_MiSTer_ch96](https://github.com/shaeon/Osborne_MiSTer_ch96).
It follows this repository automatically: only the board wrapper and the MiSTer
framework differ, the machine is the same. Its RBF files are named
`Osborne_YYYYMMDD_ch96.rbf`.

## Building

Open `Osborne.qpf` in Quartus Prime Lite 17.0, or let GitHub Actions build it:
every push to `main` leaves the `.rbf` in the *Actions* tab, and pushing a
`v*` tag creates a release.

## Credits

- **Jeremy Soller (jackpot51)**: original Osborne_MiSTer project.
- **T80** Z80 core: Daniel Wallner, with fixes by Sorgelig and the MiSTer
  community.
- **wd1793**: Viacheslav Slavinsky and Sorgelig, adapted here for the Osborne
  disk formats.
- **MiSTer framework** (`sys/`): Sorgelig and the MiSTer-devel community.
- **Chameleon96**: MiSTer framework for the board by Manuel Teira (teiram),
  [Template_MiSTer_ch96](https://github.com/teiram/Template_MiSTer_ch96);
  first port by Maverick (Maverick-Shark).
- **MAME** `osborne1` driver (Wilbert Pol, Vas Crabb and the MAME team): main
  hardware reference.

## Thanks

To the **Retro-Wiki FPGA-dev Team**, especially **Ron, Manuel (teiram), Somhi,
Roderick, Rampa, Kyp and Benito**, for their help and patience.

## AI assistance and resources

Parts of this core were developed with the assistance of Claude (Anthropic),
used for code, simulation and documentation. Access to Claude was provided by
Advanced Computer Trading, S.L. (actsl.com), which also authorises the
publication of this work under the license below. All design decisions,
integration, testing on real hardware and final review were carried out by the
author, Shaeon (Carlos Palmero).

## License

Copyright (C) 2024 Jeremy Soller, (C) 2026 Shaeon (Carlos Palmero).

This program is free software: you can redistribute it and/or modify it under
the terms of the **GNU General Public License** as published by the Free
Software Foundation, either **version 3** of the License, or (at your option)
any later version. See [LICENSE](LICENSE).

The original repository shipped the GPL v2 text from the MiSTer template, but
several MiSTer framework modules it already included (`hps_io`, `sd_card`,
`scandoubler`, `ddr_svc`) are GPL v3 or later, so the combined work has to be
GPL v3. Third-party files keep their own copyright notices and licenses.

## Disclaimer

This project is provided **"as is", without warranty of any kind**, express or
implied. In no event shall the authors or contributors be liable for any claim,
damages or other liability arising from the use of this software, of the
hardware it runs on, or of any connected equipment. Use it at your own risk.

Osborne is a trademark of its respective owners. This project is not affiliated
with or endorsed by them.
