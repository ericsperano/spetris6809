SHELL=/bin/bash -o pipefail
DSK:=spetris.dsk
SRC := spetris.asm
ASM := lwasm
ASM_FLAGS := -9bl -p cd
OBJ := ${SRC:asm=bin}
ROM := ${SRC:asm=rom}
MAME := mame
MAME_ARGS := coco3 -window -nomax -flop1

.PHONY: all

all: $(DSK)

$(DSK) : $(OBJ)
	rm -f $(DSK)
	decb dskini $(DSK)
	decb copy -0 -a -t -r autoexec.bas $(DSK),AUTOEXEC.BAS
	decb copy -0 -a -t -r autoexec.bas $(DSK),SPETRIS.BAS
	decb copy -2 -b -r $(SRC) $(DSK),SPETRIS.ASM
	decb copy -2 -b -r $(OBJ) $(DSK),SPETRIS.BIN

%.bin: %.asm Makefile
	$(ASM) $(ASM_FLAGS) -o $@ $< | tee $<.log

%.rom: %.asm Makefile 
	$(ASM) $(ASM_FLAGS) -r -o $@ $< | tee $<.log

run: all
	$(MAME) $(MAME_ARGS) $(DSK)

debug: $(ROM)
	$(MAME) -debug -debugscript debugscript coco3 -window -nomax

copy: all
	cp $(DSK) /Volumes/COCO3/

clean:
	@rm -rfv $(DSK) $(OBJ)