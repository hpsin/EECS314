.PHONY: clean all run

OUTPUT = mmps.s
INPUT = src/main.s

all: main

main: $(INPUT)
	python preprocessor.py -o $(OUTPUT) $<

clean:
	@rm -f $(OUTPUT)

run: main
	qtspim -file mmps.s
