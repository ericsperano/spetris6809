DSK:=tetris.dsk
BIN:=TETRIS.BIN

clean:
	rm -rf $(DSK)
	decb dskini $(DSK)

all: clean
	decb copy -0 -a -t -r autoexec.bas $(DSK),AUTOEXEC.BAS
	decb copy -0 -a -t -r autoexec.bas $(DSK),T.BAS
	lwasm -9bl -p cd -o$(BIN) tetris.asm |tee output.log
	decb copy -2 -b -r $(BIN) $(DSK),$(BIN)

run: all
	mame coco3 -window -nomax -flop1 $(DSK)

debug: all
	mame coco3 -window -nomax -debug -flop1 $(DSK)

copy: all
	cp $(DSK) /Volumes/COCO3/
