# MIDI MIPS Player and Synthesizer

```
                                  |\
             __  __ __  __ ____   | |
            |  \/  |  \/  |  _ \  |/
            | |\/| | |\/| | |_) |/|_
            | |  | | |  | |  __///| \
            |_|  |_|_|  |_|_|  | \|_ |
			                    \_|_/
								  |
							     @'
    _______________________________________________________
   |:::::: o o o o . |..... . .. . | [45]  o o o o o ::::::|
   |:::::: o o o o   | ..  . ..... |       o o o o o ::::::|
   |::::::___________|__..._...__._|_________________::::::|
   | # # | # # # | # # | # # # | # # | # # # | # # | # # # |
   | # # | # # # | # # | # # # | # # | # # # | # # | # # # |
   | # # | # # # | # # | # # # | # # | # # # | # # | # # # |
   | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
   |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|
```

## Console commands

- `play` - plays music added or loaded thus far
- `play n v d i` - plays a single note n, with velocity v, for duration n on instrument i
- `add n v d i` - adds a note n, with velocity v, and duration d, to the working track using instrument i
- `cat` - display a listing of notes in the track thus far
- `load f` - load a previously saved MIDI file from file location f.
- `save f` - save the working track to file location f
- `help` - display commands available

Durations are a number of 16th notes.  Quarter notes are 480ms each. 

## Instruments:

**TBD based on patch availability**


## Velocity

Valid velocities are:

- `pp` pianissimo
- `p` piano
- `mp` mezzopiano
- `mf` mezzoforte
- `f` forte
- `ff` fortissimo

## Midi stored internally as 8 byte sequences:

```
tt tt tt tt ci nn vv vv
```

- `t` - Time delta (in ticks, variable-length quantity[7-bit])
- `c` - MIDI Command (9 for on, 8 for off)
- `i` - Instrument (channel, in reality, 0-15)
- `n` - Note (0-127)
- `v` - Velocity (0x80vv, last byte contains usable velocity)

