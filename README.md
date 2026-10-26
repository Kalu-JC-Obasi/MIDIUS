# MIDIUS

**A musical arcade shooter you play with a MIDI keyboard.** Turn a knob to aim your ship, then play keys to fire. Every shot is a note, so surviving the game means making music.

Made in [ChucK](https://chuck.stanford.edu/) and [ChuGL](https://chuck.stanford.edu/chugl/) for MUSIC 256A / CS 476A (*Music, Computing, Design*) at Stanford's CCRMA, Fall 2025. It was my first solo game project.

![MIDIUS gameplay](docs/media/Midius1.png)

▶️ **[Gameplay demo](https://youtu.be/0iaNU3rOVtA)** · 🌐 **[Project page on CCRMA](https://ccrma.stanford.edu/~kjcobasi/256A/Final/)** · Development milestones: [1](https://www.youtube.com/watch?v=hDZfXxSSPhw), [2](https://www.youtube.com/watch?v=jv7nr3wX0Lc)

---

## About

MIDIUS borrows the look and feel of 1970s and '80s arcade shooters like *Space Invaders*, *Galaga*, *Sinistar* and *Gradius* (which inspired the name). Enemies close in on your ship from every direction, and you fight back with a MIDI keyboard instead of a joystick. The mechanics are deliberately simple; the fun comes from turning arcade reflexes into playing music.

## How to play

| Control | Action |
|---|---|
| **Rotary knob** | Rotate the ship a full 360° to aim |
| **Any key** | Fire a bullet; each key plays its own note |
| **Labelled key** | Coloured enemies can only be destroyed by bullets of their colour. Each is labelled with the key to press. |

- **Goal:** survive as long as you can. Each enemy that reaches your ship costs 1 health point (maximum 10); at 0, the game ends.
- **Difficulty:** the longer you survive and the more enemies you defeat, the faster enemies spawn and move.

**Power-ups** (shoot them to collect):

| Power-up | Effect |
|---|---|
| 🛡️ Shield | A ring blocks enemies for 5 seconds. Enemies it blocks give no points. |
| ➕ Health pack | Restores 1 health point |
| ✖️2 Point multiplier | Double points for 5 seconds |
| 💣 Explosive ammo | For 5 seconds, bullets become bombs that destroy every enemy in a small area |

## Requirements

- **A MIDI keyboard controller** with at least 13 velocity-sensitive keys and at least one rotary knob. I used an [Arturia MiniLab 3](https://www.arturia.com/products/hybrid-synths/minilab-3/overview); similar controllers should work.
- **[ChucK](https://chuck.stanford.edu/release/) with ChuGL**, which comes with recent ChucK releases.
- *Optional:* Python 3 with `mido` and `python-rtmidi` (`pip install mido python-rtmidi`) to run the MIDI monitor.

## Running the game

1. Plug in your MIDI controller.
2. From this folder, run:
   ```
   chuck midius.ck
   ```
   The game opens fullscreen and connects to the first MIDI device it finds (device `0`).
3. **If the knob doesn't rotate the ship:** run `python midimonitor.py`, turn your knob, and note the `control=` number it prints. Then set `TARGET_CC` near the top of `midius.ck` to that number. The default is 93.
4. **If the wrong MIDI device opens:** change `midiDevice` in `midius.ck`. ChucK numbers devices from 0.

## Files

| File | What it is |
|---|---|
| `midius.ck` | The whole game: graphics, gameplay, sound and MIDI input |
| `midimonitor.py` | A small tool that prints incoming MIDI messages, for finding your knob's CC number |
| `*.wav` | Music and sound effects |
| `PressStart2P-vaV7.ttf` | The pixel font used in the game |

## Credits

- Designed and programmed by Kalu Obasi.
- Thanks to Ge Wang, Eito, Kunwoo, Andrew and the Fall 2025 MUSIC 256A class at CCRMA.
- Font: *Press Start 2P* by CodeMan38, used under the [SIL Open Font License](OFL.txt).
<!-- CHECK: Did you make all of the .wav files yourself? If any came from elsewhere (e.g. freesound.org), credit them here with their licenses. Then delete this comment. -->

## License

Code is released under the MIT License (see [LICENSE](LICENSE)). The font is under its own license (see [OFL.txt](OFL.txt)).
