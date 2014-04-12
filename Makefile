.PHONY: clean all run

OUTPUT = mmps.s
INPUT = src/main.s src/strings.s src/backspace_handler.s src/parser.s src/play_midi.s src/file_handling.s src/cat.s src/help.s src/add.s

all: main

main: $(INPUT)
	python preprocessor.py -o $(OUTPUT) $(INPUT)

clean:
	@rm -f $(OUTPUT)

run: main
	mars mmps.s
