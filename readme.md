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
- `A` to move left, `D` move right, `Spacebar` to jump.
- `P`: Press this to immediately skip to the next level.
- `O`: Press this to immediately reset the current level.


The goal of each level is to move Squarebot into the position of the exit door. The way to do this various with each level. Some will require the clever use of the available powerups, while others may test you on more mechanical skills.

There are no inherent borders on the screen (although these can be added by just adding surrounding walls in your levels). The game only verifies that Squarebot is moving into a position within valid screen memory range (0x1e00 to 0x1ff9). This is intentional, and provides another mechanic to use when solving each level.
 

It's possible that it becomes unable to progress in certain levels (soft-locked). For example, this may happen if a provided powerup wasn't used correctly. In this case, the Level Reset button ("O") will prove to be very useful.


### Powerups

There are three powerups in Squarebot:
- **Booster**: After getting the booster (colliding with the booster powerup character), your next jump will be twice as high. Only one can be held at a time.
- **Key**: After getting the key, the next locked door that you collide with will disappear, allowing you to access whatever space (if any) it may have been blocking. Only one can be held at a time.
- **Gravity**: This powerup reverses gravity -- the ceiling becomes the floor, and vice versa. It can be flipped back to normal by grabbing another gravity powerup.


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
| 0101 | Gravity Powerup | #  |
| 0110 | Exit (complete current level) | E  |
| 0111 | Platform | _ |
| 1001 | Spike | S |
| 1000 | Key powerup |  K |
| 1011 | Booster powerup | B |

Raw level data (see `data/levels/ascii_levels/`) are 506 characters on a 22x23 grid, essentially representing what you'd see on the VIC-20. The table above tells us which characters map to which level elements. 

For example, see this simple raw data for a level:
```
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
......................
0....................E
```

Here, we have almost nothing but blank space (`.`). Squarebot starts in the bottom left corner (`0`), and to complete the level, will only need to move right to the exit (`E`).


A Python script `data/levels/generateLevelBinary.py` is used to convert this ASCII data into the format just above, and reduce it down to 253 bytes. After converting the level data into Squarebot's format, the script compressed the data via run length encoding. 

To create a custom level, you must have Python (script was developed with Python 3.10.5) installed. The steps are:
1. Create a 22x23 grid of characters, consisting of characters in the ASCII column in the table above. Use previous levels as reference points if confused. The script isn't *too* restrictive with what will pass as a level.
  
2. Once you've created the level, run `python generateLevelBinary.py <path to your custom ASCII> <output path>`, replacing with the path to your custom level file, and where you'd like the Squarebot-formatted binary to be.

3. In main.s, find the `include` directive where the first level is included. Replace the file path here to the path of the binary outputted by `generateLevelBinary.py` (do NOT use the path to your ASCII file).

4. Run `make` in the base directory of the repository to build a new .prg file with your custom level. Run this via `make run` or `xvic <path to generated prg file>`.

