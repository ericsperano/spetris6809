*******************************************************************************
* Tetris for my Color Computer 3                                              *
*******************************************************************************
PrepPieceDraw   MACRO
                CLRA
                LDB     CurrentX
                TFR     D,X
                LDB     CurrentY
                TFR     D,Y
                LDA     CurrentPiece
                LDB     CurrentRotation
                ENDM
GetPieceStruct  MACRO
                ENDM
*******************************************************************************
                ORG     $3F00
Start           JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     InitGame
                JSR     DrawInfo
                JSR     NewPiece
                JSR     NewPiece
                JSR     DrawNextPiece

                CLRA
                LDB     #1
                TFR     D,X
                LDB     #0
                TFR     D,Y
                LDA     #1
                LDB     #2
                *JSR     DrawPiece
                *JSR     DoesPieceFit
                *LDA     pieceFitFlag



MainLoop        LDA     HasToDraw
                BEQ     doSleep                ; HasToDraw is 0, don't draw
                JSR     DrawField
                PrepPieceDraw
                JSR     DrawPiece
                CLR     HasToDraw

doSleep         JSR     Sleep
                LDA     SpeedCount
                INCA
                STA     SpeedCount
                CMPA    Speed                   ; did speedcount reach speed?
                BNE     PollKeyboard            ; no, piece wont move down
                LDA     #1
                STA     ForceDown
                STA     HasToDraw
                CLR     SpeedCount
PollKeyboard    JSR     [POLCAT]                ; Polls keyboard
                BEQ     chkForceDown            ; No key KeyUpPressed
                CMPA    #KeyUp
                BEQ     PressUp
                CMPA    #KeySpace
                BEQ     PressSpc
                CMPA    #KeyEscape
                BEQ     EndGame
                JMP     chkForceDown            ; ignore that key

PressUp         LDA     CurrentRotation
                INCA
                CMPA    #4
                BNE     saveRotation
                CLRA
saveRotation    STA     CurrentRotation
                LDA     #1                      ; a key was pressed so we have to draw
                STA     HasToDraw
                JMP     chkForceDown

PressSpc        LDD     #FallSleepTime
                STD     SleepTime



chkForceDown    LDA     ForceDown
                BEQ     MainLoop                ; force down is 0, don't increment y
                INC     CurrentY
                CMPY    #13
                BEQ     EndGame
                CLR     ForceDown
                JMP     MainLoop

EndGame         JSR     RestoreVideoRAM         ; Cleanup and end execution
                RTS
*******************************************************************************
* DoesPieceFit:
* A:            Piece Index
* B:            Rotation
* X:            X position
* Y:            Y position
*******************************************************************************
DoesPieceFit    PSHU    Y,X,A,B,CC
                LDA     #1
                STA     pieceFitFlag
                TFR     Y,D                     ; b == y position
                LDA     #32                     ; 32 cols per line
                MUL
                ADDD    3,U                     ; add X
                ADDD    #Field
                TFR     D,Y                     ; Y == field pos where we start to check
                ADDD    #(3*32)+4               ; where we stop to check
                PSHU    D                       ; is saved on the stack
                LDA     3,U                     ; piece to check
                LDB     #PieceStructLen
                MUL
                ADDD    #Pieces
                TFR     D,X                     ; X now points to the beginning of the piece struct to check
                LDA     #PieceLen
                LDB     4,U                     ; rotation (0 to 4)
                MUL
                LEAX    D,X                     ; x now should point to the good rotated shape to draw
dpfLoopRow0     LDB     #4                      ; 4 "pixels' per row
dpfLoopRow1     LDA     ,X+
                CMPA    #Dot
                BNE     dpfCheck                ; not a dot, we must check
                LEAY    1,Y                     ; won't check but still need to move to next pos on the field
                JMP     dpfEndCheck
dpfCheck        LDA     ,Y+                     ; the char to draw, from the stack
                CMPA    #ChSpc
                BEQ     dpfEndCheck
                CLR     pieceFitFlag            ; piece does not fit
                JMP     dpfEnd
dpfEndCheck     DECB
                BNE     dpfLoopRow1
                CMPY    ,U                     ; are we done checking?
                BGE     dpfEnd
                LEAY    (FieldWidth-4),Y                    ; move at the beginning of next line on video ram (32-width=28)
                JMP     dpfLoopRow0
dpfEnd          PULU    D
                PULU    Y,X,A,B,CC              ; restore the registers
                RTS

*******************************************************************************
Sleep           PSHU    X,CC
                LDX     SleepTime
sleepLoop       LEAX    -1,X
                BNE     sleepLoop
                PULU    X,CC
                RTS
*******************************************************************************
InitGame        PSHU    A,B,CC
                LDD     $112                    ; timer value
                STD     Seed
                CLR     Score
                CLR     SpeedCount
                LDA     20
                STA     Speed
                PULU    A,B,CC
                RTS
*******************************************************************************
NewPiece        PSHU    A,B,CC
                LDD     #RegSleepTime
                STD     SleepTime
                LDA     NextPiece
                STA     CurrentPiece
                LDA     #1
                STA     HasToDraw
                LDA     #(FieldWidth/2)-2
                STA     CurrentX
                CLR     CurrentY
                JSR     Random                  ; Random number in D
                ;ANDA    #%01111111              ; no negative number TODO better solution than CLRA
                CLRA

                STD     Dividend
                LDA     #7                      ; 7 different pieces
                STA     Divisor
                ; do division
                LDA     #8
                STA     Remainder
                LDD     Dividend
npDivide        ASLB
                ROLA
                CMPA    Divisor
                BCS     npCheckCount
                SUBA    Divisor
                INCB
npCheckCount    DEC     Remainder
                BNE     npDivide
                ;STA     Remainder
                ;STB     Quotient
                STA     NextPiece
                PULU    A,B,CC
                RTS
*******************************************************************************
* From 6809 Machine Code Programming (David Barrow).pdf p.34
Random          PSHS    D
                LDD     Seed
                ASLB
                ROLA
                ADDD    ,S
                STD     ,S                      ;5, (S) = 3R
                ASLB                            ;2,
                ROLA                            ;2, D = 2 * 3R
                PSHS    B                       ;6, (S) = 2 • 256 * 3R (hibyte)
                ASLB                            ;2,
                ROLA                            ;2, D = 4 * 3R
                ASLB                            ;2,
                ROLA                            ;2, D = 8 * 3R
                ADDD    1,S                     ;7, D = 9 * 3R
                STD     1,S                     ;6, (S+I) = 3 *3 * 3R
                PULS    A                       ;6,
                LDB     #41                     ;2, D = 2 • 256 • 3 R + 41
                SUBD    ,S++
                STD     Seed
                RTS                             ;5, exit, D = new R.
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
DrawPiece       PSHU    CC
                PSHU    B
                PSHU    A
                PSHU    X
                PSHU    Y

                LDX     #PiecesColor
                LDA     A,X
                PSHU    A                       ; the char used to draw

                LDD     1,U                     ; y position
                LDA     #32                     ; 32 cols per line
                MUL
                ADDD    3,U                     ; add X
                ADDD    #VideoRAM
                TFR     D,Y                     ; Y == video memory where we start to draw
                ADDD    #(3*32)+4               ; where we stop to draw
                PSHU    D                       ; is saved on the stack
                LDA     6,U                     ; piece to draw
                LDB     #PieceStructLen
                MUL
                ADDD    #Pieces
                TFR     D,X                     ; X now points to the beginning of the piece struct to draw
                LDA     #PieceLen
                LDB     7,U                     ; rotation (0 to 4)
                MUL
                LEAX    D,X                     ; x now should point to the good rotated shape to draw
dpLoopRow0      LDB     #4                      ; 4 "pixels' per row
dpLoopRow1      LDA     ,X+
                CMPA    #Dot
                BNE     dpDraw                  ; not a dot, we draw it on screen then
                LEAY    1,Y                     ; won't draw but still need to move to next pos on screen
                JMP     dpEndDraw
dpDraw          LDA     2,U                     ; the char to draw, from the stack
                STA     ,Y+
dpEndDraw       DECB
                BNE     dpLoopRow1
                CMPY    ,U                     ; are we done drawing?
                BGE     dpEnd
                LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                JMP     dpLoopRow0
dpEnd           PULU    D
                PULU    A
                PULU    Y
                PULU    X
                PULU    A
                PULU    B
                PULU    CC
                *LDU     3,U                     ; drop the temp variables
                *PULU    Y,X,A,B,CC              ; restore the registers
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
RegSleepTime    EQU     200
FallSleepTime   EQU     1

KeyUp		    EQU	    $5E		                ; UP key
KeyDown		    EQU 	$0A		                ; DOWN key
KeyLeft         EQU     $08
KeyRight        EQU     $09
KeyEscape       EQU     $03                     ; Break
KeySpace        EQU     $20
*******************************************************************************
*******************************************************************************
pieceFitFlag    FCB     0


Score           FDB     0
CurrentX        FCB     0
CurrentY        FCB     0
CurrentPiece    FCB     0
NextPiece       FCB     0
CurrentRotation FCB     0
ForceDown       FCB     0
Speed           FCB     0
SpeedCount      FCB     0
HasToDraw       FCB     0
SleepTime       FDB     0

Seed            FDB     0

Dividend        FDB     0
Divisor         FCB     0
Remainder       FCB     0
Quotient        FCB     0
*******************************************************************************
PiecesColor     FCB     128+15+(16*7)           ; color piece 1
                FCB     128+15+16               ; color piece 2
                FCB     128+15+(16*2)           ; color piece 3
                FCB     128+15+(16*3)           ; Color piece 4
                FCB     128+15+(16*4)           ; Color piece 5
                FCB     128+15+(16*5)           ; Color piece 6
                FCB     128+15+(16*6)           ; Color piece 7
                FCB     128+15                  ; clear

PieceLen        EQU     16
PieceStructLen  EQU     4*PieceLen              ; 4 different rotations
Pieces          FCC     /..X...X...X...X./      ; rotation 0 piece 0
                FCC     /........XXXX..../      ; rotation 1
                FCC     /.X...X...X...X../      ; rotation 2
                FCC     /....XXXX......../      ; rotation 3
                FCC     /..X..XX...X...../      ; rotation 0 piece 1
                FCC     /......X..XXX..../      ; rotation 1
                FCC     /.....X...XX..X../      ; rotation 2
                FCC     /....XXX..X....../      ; rotation 3
                FCC     /.....XX..XX...../      ; rotation 0 piece 2
                FCC     /.....XX..XX...../      ; rotation 1
                FCC     /.....XX..XX...../      ; rotation 2
                FCC     /.....XX..XX...../      ; rotation 3
                FCC     /..X..XX..X....../      ; rotation 0 piece 3
                FCC     /.....XX...XX..../      ; rotation 1
                FCC     /......X..XX..X../      ; rotation 2
                FCC     /....XX...XX...../      ; rotation 3
                FCC     /.X...XX...X...../      ; rotation 0 piece 4
                FCC     /......XX.XX...../      ; rotation 1
                FCC     /.....X...XX...X./      ; rotation 2
                FCC     /.....XX.XX....../      ; rotation 3
                FCC     /.X...X...XX...../      ; rotation 0 piece 5
                FCC     /.....XXX.X....../      ; rotation 1
                FCC     /.....XX...X...X./      ; rotation 2
                FCC     /......X.XXX...../      ; rotation 3
                FCC     /..X...X..XX...../      ; rotation 0 piece 6
                FCC     /.....X...XXX..../      ; rotation 1
                FCC     /.....XX..X...X../      ; rotation 2
                FCC     /....XXX...X...../      ; rotation 3
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
VideoRAMBuffer  RMB     32*16
                END     Start
