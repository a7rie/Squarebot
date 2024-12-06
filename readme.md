# Squarebot

Retro puzzle game for the unexpanded VIC-20, written in 6502 Assembly. Developed by Amin Elnasri, Jesse Dirks, and Gui Marques.


## How to Run
To just run the executable, only [`xvic`](https://vice-emu.sourceforge.io/), a VIC-20 emulator, is required. In the base directory of this repository, simply run the `<path to xvic> ./out/main.prg`.

To compile the code into your own .prg and .lst files, you will need [`dasm`](https://dasm-assembler.github.io/), a macro-assembler with support for 6502 assembly. Make is not strictly necessary, but very helpful for development as there are several files that our main, entrypoint file `src/main.s` is dependent on. Commands to compile can be found in the Makefile.


## Directory Structure

- `/data/` - Contains level data and title screen data for the game, and the code used to generate them.
  - `/data/titleScreenData_compressed` - Run-length encoded binary data for the title screen.
  - `/data/levels` Contains all level-related code and data. More on this further down.
- `/src/` - Contains source code to Squarebot. The entry point is `main.s`.
- `/out/` - Pre-compiled output of Makefile; use to run Squarebot via `xvic` if you don't want to compile it yourself.



## Gameplay and Controls

At the title screen, press `Spacebar` to begin the first level. 
- `A` to move left, `D` move right.
- `Q` to jump to the left, `R` to jump to the right, `Spacebar` for an undirected jump.
- `P`: Press this to immediately skip to the next level.
- `R`: Press this to immediately reset the current level.


The goal of each level is to move Squarebot into the position of the exit door. The way to do this various with each level, and will often require the use of one or more powerups.


It's possible that it becomes unable to progress in certain levels (soft-locked). For example, this may happen if a provided powerup wasn't used correctly. In this case, the Level Reset button ("O") will prove to be very useful.


### Powerups

Squarebot has 4 sides, and one powerup can be attached to each side at a time. Hence, you may have up to 4 powerups attached to Squarebot at once.

There are two powerups in Squarebot:
- **Booster**: Squarebot moves twice as fast in the direction **opposite** of where the Booster is attached. This applies to normal movement, as well as jumps. For example, if the powerup is attached to the right, each movement to the left will move Squarebot **two** characters to the left instead of one.
    - If the booster on the bottom, each jump will be 2x as high.
    - If Squarebot collides with a breakable wall **while** moving in the opposite direction of the booster, the wall will break.
- **Key**: Squarebot can also have the key powerup attached to any of his four sides. The key powerup will unlock any locked walls it interacts with. It is **single use**; the powerup will disappear after it unlocks its first wall.
  - There are also locked exits; these will turn into a normal exit if they collide with a key, allowing you to complete the level.

## Levels

Levels are essentially frames of the VIC-20's screen, compressed with run-length encoding.  In the level data, each byte represents two consecutive characters on the screen. The first four bits represent the “element” of the first character, and the next four bits represent the element of the character directly after.

Here's a mapping of how we map each four bit pattern to level element:

| Four bit pattern | Level element | ASCII |
| -------- | ------- |  --- |
| 0000 | Blank space |  . |
| 0001 | Player Starting Position  | 0  |
| 0010 | Wall |  W |
| 0011|  Breakable Wall |  T |
| 0100 | Locked Wall |  L |
| 0110 | Exit (complete current level) | E  |
| 0111 | Platform | _ |
| 1001 | Spike | S |
| 1000 | Key powerup |  K |
| 1010 | Booster powerup | B |
| 1011 | Locked Exit | X |

Raw level data (see `data/levels/ascii_levels/`) is 420 characters on a 20x21 grid. We draw borders on the 22x23 screen on the VIC-20, and the level data only consists of the characters within this border. The ASCII column of the table above tells us which characters map to which level elements. 

For example, see this simple raw data for a level:
```
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
....................
.0..................
...................E
```

Here, we have almost nothing but blank space (`.`). Squarebot starts in the bottom left corner (`0`), and to complete the level, will only need to move right to the exit (`E`).


A Python script `data/levels/generateLevelBinary.py` is used to convert this ASCII data into the format just above, and reduce it down to 210 bytes. After converting the level data into Squarebot's format, the script compresses the data via run length encoding. 

The Makefile is setup so that the Python script will run on every file in `/data/levels/ascii_levels`, and the output will be placed in `/data/levels/binary_levels`. Creating a custom level is as easy as:
1. Update paths at the top of the Makefile; ensure paths to Python, Xvic, and Dasm are all correct.
2. Create a file containing your custom level in the `/data/levels/ascii_levels` directory.
3. Run `make` -- look at the output, specifically when `python generateLevelBinary <your file>..` is run; ensure no errors were thrown.
4. The `include` directives right after the `level_data_start` label within `main.s` determine which levels are included in the game, and in what order. Either add an `include` statement to include the path to your custom binary, or replace an existing one, to add your level to the game.