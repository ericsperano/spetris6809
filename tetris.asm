*******************************************************************************
* Tetris for my Color Computer 3                                              *
*******************************************************************************
                ORG     $3F00
Start           JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     DrawInfo
                JSR     DrawField
                JSR     DrawNextPiece


                LDD     #$0100                   ; Piece to draw & rotation
                LDX     #5                      ; at X=5
                LDY     #3                      ; and Y=3
                JSR     DrawPiece
GetKey0         JSR     [POLCAT]                ; Polls keyboard
                BEQ     GetKey0

                JSR     DrawField
                LDD     #$0101                   ; Piece to draw & rotation
                LDX     #5                      ; at X=5
                LDY     #3                      ; and Y=3
                JSR     DrawPiece
GetKey1         JSR     [POLCAT]                ; Polls keyboard
                BEQ     GetKey1

                JSR     DrawField
                LDD     #$0102                   ; Piece to draw & rotation
                LDX     #5                      ; at X=5
                LDY     #3                      ; and Y=3
                JSR     DrawPiece
GetKey2         JSR     [POLCAT]                ; Polls keyboard
                BEQ     GetKey2

                JSR     DrawField
                LDD     #$0103                   ; Piece to draw & rotation
                LDX     #5                      ; at X=5
                LDY     #3                      ; and Y=3
                JSR     DrawPiece
GetKey3         JSR     [POLCAT]                ; Polls keyboard
                BEQ     GetKey3

                JSR     RestoreVideoRAM         ; Cleanup and end execution
                RTS


*******************************************************************************


*******************************************************************************
DrawField       PSHU    A,B,X,Y,CC
                LDY     #VideoRAM               ; Y points to the real video ram
                LDX     #Field                  ; X points to the intro text
dfLoop1         LDB     #FieldWidth
dfLoop2         LDA     ,X+                     ; Load in A the byte to display
                STA     ,Y+                     ; Put A in video ram
                DECB                            ; Decrement counter of chars to display
                BNE     dfLoop2                 ; Loop if more to display for this row
                TFR     Y,D
                ADDD    #(32-FieldWidth)
                TFR     D,Y
                CMPY    #$600                   ; End of video ram?
                BNE     dfLoop1                 ; Loop if more to display
                PULU    A,B,X,Y,CC
                RTS
*******************************************************************************
DrawInfo        LDY     #(VideoRAM+FieldWidth)  ; Y points to the real video ram
                LDX     #Info                   ; X points to the intro text
diLoop1         LDB     #(32-FieldWidth)
diLoop2         LDA     ,X+                     ; Load in A the byte to display
                STA     ,Y+                     ; Put A in video ram
                DECB                            ; Decrement counter of chars to display
                BNE     diLoop2                 ; Loop if more to display for this row
                TFR     Y,D
                ADDD    #FieldWidth
                TFR     D,Y
                CMPY    #$60C                   ; End of video ram?
                BNE     diLoop1                 ; Loop if more to display
                RTS
*******************************************************************************
* DrawPiece:
* A:            Piece Index
* B:            Rotation
* X:            X position
* Y:            Y position
*******************************************************************************
DrawPiece       PSHU    Y,X,A,B,CC
                TFR     Y,D                     ; b == y position
                LDA     #32                     ; 32 cols per line
                MUL
                ADDD    3,U                     ; add X
                ADDD    #VideoRAM
                TFR     D,Y                     ; Y == video memory where we start to draw
                ADDD    #(3*32)+4               ; where we stop to draw
                PSHU    D                       ; is saved on the stack

                LDA     3,U                     ; piece to draw
                LDB     #PieceStructLen
                MUL
                ADDD    #Pieces
                TFR     D,X                     ; X now points to the beginning of the piece struct to draw
                LDA     ,X+
                PSHU    A                       ; save the char to draw in the stack
                LDA     #PieceLen
                LDB     5,U                     ; rotation (0 to 4)
                MUL
                LEAX    D,X                     ; x now should point to the good rotated shape to draw
dpLoopRow0      LDB     #4                      ; 4 "pixels' per row
dpLoopRow1      LDA     ,X+
                CMPA    #Dot
                BNE     dpDraw                  ; not a dot, we draw it on screen then
                LEAY    1,Y                     ; won't draw but still need to move to next pos on screen
                JMP     dpEndDraw
dpDraw          LDA     ,U                      ; the char to draw, from the stack
                STA     ,Y+
dpEndDraw       DECB
                BNE     dpLoopRow1
                CMPY    1,U                     ; are we done drawing?
                BGE     dpEnd
                LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                JMP     dpLoopRow0
dpEnd           PULU    A
                PULU    D
                *LDU     3,U                     ; drop the temp variables
                PULU    Y,X,A,B,CC              ; restore the registers
                RTS
*******************************************************************************
* DrawNextPiece:
* A: pieceIdx
*******************************************************************************
DrawNextPiece   PSHU    A,B,X,Y,CC
                LDA     #ClearPiece
                CLRB
                LDX     #(FieldWidth+2)
                LDY     #5
                JSR     DrawPiece
                LDA     NextPiece
                JSR     DrawPiece
                PULU    A,B,X,Y,CC
                RTS
*******************************************************************************
SaveVideoRAM    LDY     #VideoRAM       ; Y points to the real video ram
                LDX     VideoRAMBuffer  ; X points to the saved buffer video ram
LoopSaveVRAM    LDA     ,Y+             ; Load in A the real video byte
                STA     ,X+             ; And store it in the saved buffer
                CMPY    #$600           ; At the end of the video ram?
                BNE     LoopSaveVRAM
                RTS
*******************************************************************************
RestoreVideoRAM LDY     #VideoRAM       ; Y points to the real video ram
                LDX     VideoRAMBuffer  ; X points to the saved buffer video ram
LoopRestoreVRAM LDA     ,X+             ; Load in A the saved video byte
                STA     ,Y+             ; And put in in real video ram
                CMPY    #$600           ; At the end of the video ram?
                BNE     LoopRestoreVRAM
                RTS
*******************************************************************************
FieldWidth      EQU     12
Dot             EQU     $2E
VideoRAM        EQU     $400                    ; video ram address
POLCAT	        EQU	    $A000	                ; read keyboard ROM routine
ChSpc           EQU     128+(16*0)+15
ChFieldLeft     EQU     128+(16*0)+10
ChFieldRight    EQU     128+(16*0)+5

KeyUp		    EQU	    $5E		                ; UP key
KeyDown		    EQU 	$0A		                ; DOWN key
*******************************************************************************
*******************************************************************************
*******************************************************************************
PieceLen        EQU     16
PieceStructLen  EQU     1+(4*PieceLen)          ; character + 4 different rotations

NextPiece       FCB     $3                      ; next piece to draw, TODO random
Pieces          FCB     128+15+(16*7)           ; color piece 1
                FCC     /..X...X...X...X./      ; rotation 0
                FCC     /........XXXX..../      ; rotation 1
                FCC     /.X...X...X...X../      ; rotation 2
                FCC     /....XXXX......../      ; rotation 3
                FCB     128+15+16               ; color piece 2
                FCC     /..X..XX...X...../      ; rotation 0
                FCC     /......X..XXX..../      ; rotation 1
                FCC     /.....X...XX..X../      ; rotation 2
                FCC     /....XXX..X....../      ; rotation 3
                FCB     128+15+(16*2)           ; color piece 3
                FCC     /.....XX..XX...../      ; rotation 0
                FCC     /.....XX..XX...../      ; rotation 1
                FCC     /.....XX..XX...../      ; rotation 2
                FCC     /.....XX..XX...../      ; rotation 3
                FCB     128+15+(16*3)           ; Color piece 4
                FCC     /..X..XX..X....../      ; rotation 0
                FCC     /.....XX...XX..../      ; rotation 1
                FCC     /......X..XX..X../      ; rotation 2
                FCC     /....XX...XX...../      ; rotation 3
                FCB     128+15+(16*4)           ; Color piece 5
                FCC     /.X...XX...X...../      ; rotation 0
                FCC     /................/      ; rotation 1
                FCC     /................/      ; rotation 2
                FCC     /................/      ; rotation 3
                FCB     128+15+(16*5)           ; Color piece 6
                FCC     /.X...X...XX...../      ; rotation 0
                FCC     /................/      ; rotation 1
                FCC     /................/      ; rotation 2
                FCC     /................/      ; rotation 3
                FCB     128+15+(16*6)           ; Color piece 7
                FCC     /..X...X..XX...../      ; rotation 0
                FCC     /................/      ; rotation 1
                FCC     /................/      ; rotation 2
                FCC     /................/      ; rotation 3
                FCB     128+15                  ; clear
                FCC     /XXXXXXXXXXXXXXXX/
ClearPiece      EQU     7
Field           FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCB     ChFieldLeft,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChSpc,ChFieldRight
                FCC     /############/
Info            FCC     /````````````````````/
                FCC     /``SCOREz/
                FCC     /````````````/
                FCC     /````````````````````/
                FCC     /``NEXT`PIECEz```````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /````````````````````/
                FCC     /``/
                FCB     $5E
                FCC     /z`ROTATE`````````/
                FCC     /````````````````````/
VideoRAMBuffer  FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                END     Start
