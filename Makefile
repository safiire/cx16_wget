BINARY=wget.prg

$(BINARY): main.o args.o exehdr.o args.o string.o uart.o fileio.o stack_immediate.o
	cl65 -m $(BINARY).map -o $(BINARY) -t cx16 -C linker.cfg $^

main.o: main.s
	ca65 -I include -t cx16 -l "$@".list "$<"

args.o: args.s
	ca65 -I include -t cx16 -l "$@".list "$<"

exehdr.o: exehdr.s
	ca65 -I include -t cx16 -l "$@".list "$<"

string.o: string.s
	ca65 -I include -t cx16 -l "$@".list "$<"

uart.o: uart.s
	ca65 -I include -t cx16 -l "$@".list "$<"

fileio.o: fileio.s
	ca65 -I include -t cx16 -l "$@".list "$<"

stack_immediate.o: stack_immediate.s
	ca65 -I include -t cx16 -l "$@".list "$<"

install: $(BINARY)
	cp $(BINARY) ~/Desktop/x16/

clean:
	rm -f $(BINARY) *.list *.o *.map

run: install
	~/Desktop/x16/x16emu -rockwell -zeroram -debug -fsroot ~/Desktop/x16 -startin ~/Desktop/x16

debug: install
	~/Desktop/x16/x16emu -debug 080d -zeroram -debug -fsroot ~/Desktop/x16 -startin ~/Desktop/x16

cloc:
	@cloc . --force-lang="Assembly",inc
