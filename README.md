# UK101 on Tang Nano 20K

A complete Compukit UK101 retro computer running on the Sipeed Tang Nano 20K FPGA board, with HDMI video output and PS/2 keyboard support.

![CEGMON monitor booting on screen]()

## Features

- **MOS 6502 CPU** at ~1 MHz (27 MHz crystal ÷ 27)
- **HDMI output** — 720×480 @ 60 Hz (480p), 64×16 character display centred on screen
- **Green-on-blue phosphor** character rendering with 8×8 pixel font
- **PS/2 keyboard** support
- **CEGMON monitor ROM** (1980) — boots to `D/C/W/M` prompt
- **BASIC ROM** — press `W` at the CEGMON prompt to start
- **Persistent storage** — bitstream survives power cycles (written to onboard Winbond W25Q64 flash)

## Hardware

| Component | Details |
|-----------|---------|
| FPGA board | Sipeed Tang Nano 20K |
| FPGA | Gowin GW2AR-LV18QN88C8/I7 (GW2AR-18C) |
| Video output | HDMI via TMDS (27 MHz pixel clock, 270 MHz TMDS) |
| Keyboard | PS/2, connected to GPIO pins 76 (DATA) and 77 (CLK) |
| Flash | Winbond W25Q64 (64 Mbit, onboard SPI) |

### PS/2 Keyboard Wiring

| PS/2 pin | Signal | Tang Nano 20K |
|----------|--------|---------------|
| 1 | DATA | FPGA pin 76 |
| 3 | GND | GND |
| 4 | VCC | **5 V** (not 3.3 V) |
| 5 | CLK | FPGA pin 77 |

Internal pull-ups are configured on both CLK and DATA lines.

## Memory Map

| Address | Size | Device |
|---------|------|--------|
| `$0000–$0FFF` | 4 KB | Work RAM |
| `$A000–$BFFF` | 8 KB | BASIC ROM |
| `$D000–$D3FF` | 1 KB | Display RAM |
| `$DC00–$DFFF` | — | PS/2 keyboard |
| `$F000–$F001` | — | UART (16× 9600 baud) |
| `$F800–$FFFF` | 2 KB | CEGMON monitor ROM |

## Building

### Requirements

- [Gowin EDA Education](https://www.gowinsemi.com/en/support/download_eda/) v1.9.11 or later
- [openFPGALoader](https://github.com/trabucayre/openFPGALoader) (for flashing — see note below)

### Synthesise and place-and-route

```
gw_sh build.tcl
```

This produces `impl/pnr/uk101.fs`.

### Flash to board (permanent)

```
openFPGALoader -b tangnano20k --write-flash impl/pnr/uk101.fs
```

> **Windows note:** The Gowin Education programmer CLI has a bug that prevents embedded flash erase. Use [openFPGALoader](https://github.com/trabucayre/openFPGALoader) instead. You will also need to install the WinUSB driver for the FT2232H interfaces using [Zadig](https://zadig.akeo.ie) (replace both Interface 0 and Interface 1 with WinUSB).

The convenience script `flash.bat` does this automatically on Windows once openFPGALoader is installed via MSYS2.

## Usage

1. Power on the board — CEGMON monitor appears on screen
2. Connect a PS/2 keyboard
3. Press **`W`** to warm-start BASIC
4. Enjoy!

## Project Structure

```
uk101/
├── build.tcl          # Gowin synthesis script
├── uk101.cst          # Pin constraints
├── flash.bat          # Windows flash helper
└── src/
    ├── uk101_top.v    # Top-level: clocks, address decode, bus mux
    ├── video.v        # Video controller (HDMI timing + character renderer)
    ├── pll.v          # PLL: 27 MHz → 270 MHz TMDS clock
    ├── hdmi_tx.v      # HDMI serialiser (TMDS + OSER10 + ELVDS)
    ├── tmds_encoder.v # TMDS 8b/10b encoder
    ├── disp_ram.v     # 1 KB dual-port display RAM (Verilog, posedge)
    ├── prog_ram.v     # 4 KB work RAM (Verilog, posedge)
    ├── T65.vhd        # T65 — portable VHDL 6502 core
    ├── BasicRom.vhd   # 8 KB UK101 BASIC ROM
    ├── CegmonRom.vhd  # 2 KB CEGMON monitor ROM
    ├── CharRom.vhd    # 2 KB 8×8 character ROM
    ├── UK101keyboard.vhd  # PS/2 → UK101 keyboard matrix
    └── bufferedUART.vhd   # 6551-compatible UART
```

## Credits

This project would not exist without the work of many others:

- **[Grant Searle](http://searle.x10host.com/uk101FPGA/index.html)** — original UK101 FPGA implementation, BASIC ROM, CEGMON ROM, character ROM and keyboard matrix
- **[emard](https://github.com/emard/UK101onFPGA)** — portable VHDL fork of Grant Searle's design, used as the basis for this port
- **T65 core** — portable VHDL 6502/65C02 implementation by Daniel Wallner and contributors, via the [MiSTer](https://github.com/MiSTer-devel) community
- **[Sipeed](https://sipeed.com)** — Tang Nano 20K hardware
- **[openFPGALoader](https://github.com/trabucayre/openFPGALoader)** — open-source FPGA programmer used for flashing

## Licence

The VHDL source files (T65, UK101 keyboard, UART, ROMs) retain their original licences from their respective authors. The Verilog files written for this port (`uk101_top.v`, `video.v`, `pll.v`, `disp_ram.v`, `prog_ram.v`) are released under the MIT licence.
