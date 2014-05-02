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

## Compiling and Running

To compile the file run `make clean && make` which will create a file
called `mmps.s`. Open this file in Mars and assembly it and click
run. You will most likely need expand the console area in Mars in
order to see everything and interact with the program properly.

The preprocessor requires python and make to be installed. As you may
not have this installed we have also included a precompiled version in
the `mmps.s` file.

## Console commands

- `play` - plays music added or loaded thus far
- `play n v d i` - plays a single note n, with velocity v, for duration n on instrument i
- `add n v d i` - adds a note n, with velocity v, and duration d, to the working track using instrument i
- `add d` - adds a rest for the specified duration
- `cat` - display a listing of notes in the track thus far
- `load f` - load a previously saved MIDI file from file location f.
- `save f` - save the working track to file location f
- `help` - display commands available

Durations are a number of 16th notes.  Quarter notes are 480ms each. 

## Instruments:

- `0`: Piano
- `1`: Chromatic Percussion
- `2`: Organ
- `3`: Guitar
- `4`: Bass
- `5`: Strings
- `6`: Ensemble
- `7`: Brass
- `8`: Reed
- `9`: Pipe
- `10`: Synth Lead
- `11`: Synth Pad
- `12`: Synth Effect
- `13`: Ethnic
- `14`: Percussion
- `15`: Sound Effect


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

