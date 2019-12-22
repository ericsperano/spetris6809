DSK:=spetris.dsk
SRC := spetris.asm
OBJ := ${SRC:asm=bin}
MAME := mame coco3 -window -nomax -flop1

.PHONY: all

all: $(DSK)

$(DSK) : $(OBJ)
	decb dskini $(DSK)
	decb copy -0 -a -t -r autoexec.bas $(DSK),AUTOEXEC.BAS
	decb copy -0 -a -t -r autoexec.bas $(DSK),S.BAS
	decb copy -2 -b -r $(OBJ) $(DSK),SPETRIS.BIN

%.bin: %.asm Makefile
	lwasm -9bl -p cd -o $@ $< | tee $<.log

run: all
	$(MAME) $(DSK)

debug: all
	$(MAME) -debug $(DSK)

copy: all
	cp $(DSK) /Volumes/COCO3/

clean:
	@rm -rfv $(DSK) $(OBJ)