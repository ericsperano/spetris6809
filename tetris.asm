*******************************************************************************
* Tetris for my Color Computer 3                                              *
*******************************************************************************
                    ORG     $3F00
Start               JSR     SaveVideoRAM            ; save video ram to restore on exit
                    JSR     InitGame
                    JSR     DrawInfo
                    JSR     GetNextPiece
NewPiece            CLR     ForceDown
                    JSR     GetNextPiece
                    JSR     DrawNextPiece
MainLoop            LDA     HasToDraw
                    BEQ     doSleep                ; HasToDraw is 0, don't draw
                    JSR     DrawField
                    JSR     DrawCurrentPiece
                    CLR     HasToDraw
doSleep             LDA     Falling                 ; skip the sleeping andd stuff if the piece is falling
                    BEQ     doSleep_
                    INC     ForceDown
                    INC     HasToDraw
doSleep_            JSR     Sleep                   ; increment the speed count
                    INC     SpeedCount
                    LDA     SpeedCount              ; and force down if it reached speed max
                    CMPA    Speed
                    BNE     pollKeyboard           ; if not go straight to poll keyboard
                    INC     ForceDown
                    INC     HasToDraw
                    CLR     SpeedCount
pollKeyboard        JSR     [POLCAT]                ; Polls keyboard
                    BEQ     chkForceDown            ; No key pressed
                    JSR     CheckKeyboard
                    LDA     QuitGame
                    BNE     EndGame                 ; quit game if QuitGame is 1
chkForceDown        LDA     ForceDown
                    BEQ     MainLoop                ; force down is 0, don't increment y
                    LDD     CurrentX                ; first check if it would fit
                    STD     DoesPieceFitX
                    LDA     CurrentY
                    INCA
                    STA     DoesPieceFitY
                    LDA     CurrentRotation
                    STA     DoesPieceFitR
                    JSR     DoesPieceFit
                    LDA     PieceFitFlag
                    BEQ     lockPiece               ; it doesnt, we lock

                    LDA     DoesPieceFitY           ; it does, increment y
                    STA     CurrentY
                    CLR     ForceDown
                    JMP     MainLoop

lockPiece           JSR     LockCurrentPiece
                    JMP     NewPiece
EndGame             JSR     RestoreVideoRAM         ; Cleanup and end execution
                    RTS
*******************************************************************************
InitGame            PSHU    A,B,CC
                    CLR     QuitGame
                    LDD     $112                    ; timer value
                    STD     Seed
                    CLR     Score
                    CLR     SpeedCount
                    LDA     20
                    STA     Speed
                    JSR     InitField
                    PULU    A,B,CC
                    RTS
*******************************************************************************
InitField           PSHU    A,Y,CC
                    LDY     #Field
                    LDA     #ChSpc
ifLoopClear         STA     ,Y+
                    CMPY    #FieldBottom
                    BNE     ifLoopClear
                    LDY     #Field
ifLoop0             LDA     #ChFieldLeft
                    STA     ,Y
                    LDA     #ChFieldRight
                    STA     (FieldWidth-1),Y
                    LEAY    FieldWidth,Y
                    CMPY    #FieldBottom
                    BNE     ifLoop0
                    PULU    A,Y,CC
                    RTS
*******************************************************************************
_DoesPieceFitCK     MACRO
                    STD     DoesPieceFitX
                    LDA     CurrentY
                    STA     DoesPieceFitY
                    LDA     CurrentRotation
                    STA     DoesPieceFitR
                    JSR     DoesPieceFit
                    LDA     PieceFitFlag
                    BEQ     endCheckKeyboard
                    ENDM
*******************************************************************************
CheckKeyboard       CMPA    #KeyLeft                ; left
                    BEQ     PressLeft
                    CMPA    #KeyRight               ; right
                    BEQ     PressRight
                    CMPA    #KeyUp                  ; Up
                    BEQ     PressUp
                    CMPA    #KeySpace               ; Spacebar
                    BEQ     PressSpc
                    CMPA    #KeyEscape              ; Break     TODO does not exit
                    LBEQ    PressBrk
                    JMP     endCheckKeyboard         ; ignore other keys
PressLeft           LDD     CurrentX
                    DECB
                    _DoesPieceFitCK
                    DEC     CurrentX+1
                    INC     HasToDraw
                    JMP     endCheckKeyboard
PressRight          LDD     CurrentX
                    INCB
                    _DoesPieceFitCK
                    INC     CurrentX+1
                    INC     HasToDraw
                    JMP     endCheckKeyboard
PressUp             LDA     CurrentRotation         ; KeyUp! Increment rotation
                    INCA
                    CMPA    #4                      ; or reset to 0 if == 4
                    BNE     pressUpEnd
                    CLRA
pressUpEnd          STA     DoesPieceFitR
                    LDD     CurrentX
                    STD     DoesPieceFitX
                    LDA     CurrentY
                    STA     DoesPieceFitY
                    JSR     DoesPieceFit
                    LDA     PieceFitFlag
                    BEQ     endCheckKeyboard
                    LDA     DoesPieceFitR
                    STA     CurrentRotation
                    INC     HasToDraw
                    JMP     endCheckKeyboard
PressSpc            INC     Falling
                ; LDD     #FallSleepTime
                ;    STD     SleepTime
                    JMP     endCheckKeyboard
PressBrk            INC     QuitGame
endCheckKeyboard    RTS
*******************************************************************************
GetNextPiece        PSHU    A,B,CC
                    CLR     Falling
                    LDD     #RegSleepTime           ; reset sleep time
                    STD     SleepTime
                    LDA     NextPiece
                    STA     CurrentPiece
                    INC     HasToDraw
                    LDD     #(FieldWidth/2)-2
                    STD     CurrentX
                    CLR     CurrentY
                    JSR     Random                  ; Random number in D
                    ;ANDA    #%01111111              ; no negative number TODO better solution than CLRA
                    CLRA
                    STD     Dividend
                    LDA     #7                      ; 7 different pieces
                    STA     Divisor
                    LDA     #8                      ; do division
                    STA     Remainder
                    LDD     Dividend
gnpDivide           ASLB
                    ROLA
                    CMPA    Divisor
                    BCS     gnpCheckCount
                    SUBA    Divisor
                    INCB
gnpCheckCount       DEC     Remainder
                    BNE     gnpDivide
                    ;STA     Remainder
                    ;STB     Quotient
                    STA     NextPiece
                    PULU    A,B,CC
                    RTS
*******************************************************************************
DrawCurrentPiece    PSHU    A,B,X,Y,CC
                    LDX     #PiecesColor            ; get the char to draw
                    LDA     CurrentPiece            ; by indexing PiecesColor
                    LDA     A,X
                    STA     dcpDrawChar             ; the char used to draw
                    LDA     #32                     ; 32 cols per line
                    LDB     CurrentY                ; y position
                    MUL
                    ADDD    CurrentX                ; add x position
                    ADDD    #VideoRAM               ; add base pointer
                    TFR     D,Y                     ; Y == video memory where we start to draw
                    ADDD    #(3*32)+4               ; where we stop to draw
                    STD     dcpDrawEndAddr
                    LDA     CurrentPiece            ; compute the offset in the pieces struct array
                    LDB     #PieceStructLen
                    MUL
                    ADDD    #Pieces                 ; add base pointer
                    TFR     D,X                     ; X now points to the beginning of the piece struct to draw
                    LDA     #PieceLen               ; Compute the offset for the rotation
                    LDB     CurrentRotation
                    MUL
                    LEAX    D,X                     ; x now should point to the good rotated shape to draw
dcpLoopRow0         LDB     #4                      ; 4 "pixels' per row
dcpLoopRow1         LDA     ,X+
                    CMPA    #Dot
                    BNE     dcpDraw                 ; not a dot, we draw it on screen then
                    LEAY    1,Y                     ; won't draw but still need to move to next pos on screen
                    JMP     dcpEndDraw
dcpDraw             LDA     dcpDrawChar             ; the char to draw, from the stack
                    STA     ,Y+
dcpEndDraw          DECB
                    BNE     dcpLoopRow1
                    CMPY    dcpDrawEndAddr          ; are we done drawing?
                    BGE     dcpEnd
                    LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                    JMP     dcpLoopRow0
dcpEnd              PULU    A,B,X,Y,CC              ; restore the registers
                    RTS
dcpDrawChar         FCB     0
dcpDrawEndAddr      FDB     0
*******************************************************************************
DrawNextPiece       PSHU    A,B,X,Y,CC
                    LDX     #PiecesColor            ; get the char to draw
                    LDA     NextPiece                ; by indexing PiecesColor
                    LDA     A,X
                    STA     dnpDrawChar             ; the char used to draw
                    LDA     #32                     ; 32 cols per line
                    LDB     #5                      ; y position
                    MUL
                    * TODO no need to compute video ram, could be EQUs
                    ADDD    #(FieldWidth+2)         ; add x position
                    ADDD    #VideoRAM               ; add base pointer
                    TFR     D,Y                     ; Y == video memory where we start to draw
                    ADDD    #(3*32)+4               ; where we stop to draw
                    STD     dnpDrawEndAddr
                    LDA     NextPiece               ; compute the offset in the pieces struct array
                    LDB     #PieceStructLen
                    MUL
                    ADDD    #Pieces                 ; add base pointer
                    TFR     D,X                     ; X now points to the beginning of the piece struct to draw
dnpLoopRow0         LDB     #4                      ; 4 "pixels' per row
dnpLoopRow1         LDA     ,X+
                    CMPA    #Dot
                    BNE     dnpDraw                 ; not a dot, we draw it on screen then
                    LDA     ClearBlock
                    JMP     dnpEndDraw
dnpDraw             LDA     dnpDrawChar             ; the char to draw, from the stack
dnpEndDraw          STA     ,Y+
                    DECB
                    BNE     dnpLoopRow1
                    CMPY    dnpDrawEndAddr          ; are we done drawing?
                    BGE     dnpEnd
                    LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                    JMP     dnpLoopRow0
dnpEnd              PULU    A,B,X,Y,CC              ; restore the registers
                    RTS
dnpDrawChar         FCB     0
dnpDrawEndAddr      FDB     0
*******************************************************************************
DrawField           PSHU    A,B,X,Y,CC
                    LDY     #VideoRAM               ; Y points to the real video ram
                    LDX     #Field                  ; X points to the intro text
dfLoop1             LDB     #FieldWidth
dfLoop2             LDA     ,X+                     ; Load in A the byte to display
                    STA     ,Y+                     ; Put A in video ram
                    DECB                            ; Decrement counter of chars to display
                    BNE     dfLoop2                 ; Loop if more to display for this row
                    LEAY    32-FieldWidth,Y
                    CMPY    #$600                   ; End of video ram?
                    BNE     dfLoop1                 ; Loop if more to display
                    PULU    A,B,X,Y,CC
                    RTS
*******************************************************************************
DrawInfo            LDY     #(VideoRAM+FieldWidth)  ; Y points to the real video ram
                    LDX     #Info                   ; X points to the intro text
diLoop1             LDB     #(32-FieldWidth)
diLoop2             LDA     ,X+                     ; Load in A the byte to display
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
Sleep               PSHU    X,CC
                    LDX     SleepTime
sleepLoop           LEAX    -1,X
                    BNE     sleepLoop
                    PULU    X,CC
                    RTS
*******************************************************************************
DoesPieceFit        PSHU    Y,X,A,B,CC
                    LDA     #1                      ; piece fit by default
                    STA     PieceFitFlag
                    LDB     DoesPieceFitY
                    LDA     #FieldWidth             ; cols per line
                    MUL
                    ADDD    DoesPieceFitX           ; add X
                    ADDD    #Field
                    TFR     D,Y                     ; Y == field pos where we start to check
                    ADDD    #(3*FieldWidth)+4       ; where we stop to check
                    STD     dpfFieldEndAddr
                    LDA     CurrentPiece
                    LDB     #PieceStructLen
                    MUL
                    ADDD    #Pieces
                    TFR     D,X                     ; X now points to the beginning of the piece struct to check
                    LDA     #PieceLen
                    LDB     DoesPieceFitR
                    MUL
                    LEAX    D,X                     ; x now should point to the good rotated shape to draw
dpfLoopRow0         LDB     #4                      ; 4 "pixels' per row
dpfLoopRow1         LDA     ,X+
                    CMPA    #Dot
                    BNE     dpfCheck                ; not a dot, we must check
                    LEAY    1,Y                     ; won't check but still need to move to next pos on the field
                    JMP     dpfEndCheck
dpfCheck            LDA     ,Y+                     ; the char to draw, from the stack
                    CMPA    #ChSpc
                    BEQ     dpfEndCheck
                    CLR     PieceFitFlag            ; piece does not fit
                    JMP     dpfEnd
dpfEndCheck         DECB
                    BNE     dpfLoopRow1
                    CMPY    dpfFieldEndAddr         ; are we done checking?
                    BGE     dpfEnd
                    LEAY    (FieldWidth-4),Y        ; move at the beginning of next line on video ram (32-width=28)
                    JMP     dpfLoopRow0
dpfEnd              PULU    Y,X,A,B,CC              ; restore the registers
                    RTS
dpfFieldEndAddr     FDB     0
*******************************************************************************
LockCurrentPiece    PSHU    Y,X,A,B,CC
                    LDX     #PiecesColor            ; get the char to draw
                    LDA     CurrentPiece            ; by indexing PiecesColor
                    LDA     A,X
                    STA     lcpDrawChar             ; the char used to draw
                    LDB     CurrentY
                    LDA     #FieldWidth             ; cols per line
                    MUL
                    ADDD    CurrentX                ; add X
                    ADDD    #Field
                    TFR     D,Y                     ; Y == field pos where we start to check
                    ADDD    #(3*FieldWidth)+4       ; where we stop to check
                    STD     lcpFieldEndAddr
                    LDA     CurrentPiece
                    LDB     #PieceStructLen
                    MUL
                    ADDD    #Pieces
                    TFR     D,X                     ; X now points to the beginning of the piece struct to check
                    LDA     #PieceLen
                    LDB     CurrentRotation
                    MUL
                    LEAX    D,X                     ; x now should point to the good rotated shape to draw
lcpLoopRow0         LDB     #4                      ; 4 "pixels' per row
lcpLoopRow1         LDA     ,X+
                    CMPA    #Dot
                    BNE     lcpLock                 ; not a dot, we must check
                    LEAY    1,Y                     ; won't check but still need to move to next pos on the field
                    JMP     lcpEndLock
lcpLock             LDA     lcpDrawChar
                    STA     ,Y+
lcpEndLock          DECB
                    BNE     lcpLoopRow1
                    CMPY    lcpFieldEndAddr         ; are we done checking?
                    BGE     lcpEnd
                    LEAY    (FieldWidth-4),Y        ; move at the beginning of next line on video ram (32-width=28)
                    JMP     lcpLoopRow0
lcpEnd              PULU    Y,X,A,B,CC              ; restore the registers
                    RTS
lcpDrawChar         FCB     0
lcpFieldEndAddr     FDB     0

*******************************************************************************
* From 6809 Machine Code Programming (David Barrow).pdf p.34
Random              PSHS    D
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
SaveVideoRAM        LDY     #VideoRAM       ; Y points to the real video ram
                    LDX     VideoRAMBuffer  ; X points to the saved buffer video ram
LoopSaveVRAM        LDA     ,Y+             ; Load in A the real video byte
                    STA     ,X+             ; And store it in the saved buffer
                    CMPY    #$600           ; At the end of the video ram?
                    BNE     LoopSaveVRAM
                    RTS
*******************************************************************************
RestoreVideoRAM     LDY     #VideoRAM       ; Y points to the real video ram
                    LDX     VideoRAMBuffer  ; X points to the saved buffer video ram
loopRestoreVRAM     LDA     ,X+             ; Load in A the saved video byte
                    STA     ,Y+             ; And put in in real video ram
                    CMPY    #$600           ; At the end of the video ram?
                    BNE     loopRestoreVRAM
                    RTS
*******************************************************************************
FieldWidth          EQU     12
Dot                 EQU     $2E
VideoRAM            EQU     $400                    ; video ram address
POLCAT	            EQU	    $A000	                ; read keyboard ROM routine
ChSpc               EQU     128+(16*0)+15
ChFieldLeft         EQU     128+(16*0)+10
ChFieldRight        EQU     128+(16*0)+5
RegSleepTime        EQU     200
FallSleepTime       EQU     1
KeyUp		        EQU	    $5E		                ; UP key
KeyDown		        EQU 	$0A		                ; DOWN key
KeyLeft             EQU     $08
KeyRight            EQU     $09
KeyEscape           EQU     $03                     ; Break
KeySpace            EQU     $20
*******************************************************************************
Score               FDB     0
CurrentX            FDB     0
CurrentY            FCB     0
CurrentPiece        FCB     0
NextPiece           FCB     0
CurrentRotation     FCB     0
ForceDown           FCB     0
Speed               FCB     0
SpeedCount          FCB     0
HasToDraw           FCB     0
SleepTime           FDB     0
DoesPieceFitX       FDB     0
DoesPieceFitY       FCB     0
DoesPieceFitR       FCB     0
PieceFitFlag        FCB     0
QuitGame            FCB     0

Falling             FCB     0
Seed                FDB     0
Dividend            FDB     0
Divisor             FCB     0
Remainder           FCB     0
Quotient            FCB     0
*******************************************************************************
PiecesColor         FCB     128+15+(16*7)           ; color piece 1
                    FCB     128+15+16               ; color piece 2
                    FCB     128+15+(16*2)           ; color piece 3
                    FCB     128+15+(16*3)           ; Color piece 4
                    FCB     128+15+(16*4)           ; Color piece 5
                    FCB     128+15+(16*5)           ; Color piece 6
                    FCB     128+15+(16*6)           ; Color piece 7
ClearBlock          FCB     128+15                  ; clear

PieceLen            EQU     16
PieceStructLen      EQU     4*PieceLen              ; 4 different rotations
Pieces              FCC     /..X...X...X...X./      ; rotation 0 piece 0
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
* TODO: rmb and set it up in init game instead
Field               RMB     FieldWidth*16
FieldBottom         FCC     /############/
Info                FCC     /``````````````````````SCOREz``````````````````````````````````NEXT`PIECEz```````/
                    FCC     /````````````````````````````````````````````````````````````````````````````````/
                    FCC     /````````````````````````````````````````````````````````````````````````````````/
                    FCC     /``````````````````````````````````````````/
                    FCB     $5E
                    FCC     /z`ROTATE`````````````````````````````/
VideoRAMBuffer      RMB     32*16
                    END     Start
