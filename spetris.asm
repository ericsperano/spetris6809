***********************************************************************************************************************
* Spétris                                                                                                             *
* Tetris Clone for my Color Computer 3                                                                                *
* TODO PieceCount to increment speed
***********************************************************************************************************************
                ORG     $3F00
Start           LDU     #UserStack
                JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     DisplayIntro
                JMP     EndGame
startNewGame    JSR     NewGame


*-----------------------------------------------------------------------------------------------------------------------
                    JSR     DrawInfo
                    JSR     GetNextPiece
NewPiece            CLR     ForceDown
                    JSR     GetNextPiece
                    JSR     DrawNextPiece
                    LDD     CurrentX                   ; first check if it would fit
                    STD     DoesPieceFitX
                    LDA     CurrentY
                    STA     DoesPieceFitY
                    LDA     CurrentRotation
                    STA     DoesPieceFitR
                    JSR     DoesPieceFit
                    LDA     PieceFitFlag
                    LBEQ    EndGame
MainLoop            LDA     HasToDraw
                    BEQ     doSleep                    ; HasToDraw is 0, don't draw
                    JSR     DrawField
                    JSR     DrawCurrentPiece
                    JSR     DisplayScore
                    CLR     HasToDraw
doSleep             LDA     Falling                    ; skip the sleeping andd stuff if the piece is falling
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
                    BEQ     lockPiece               ; it doesnt, we lock*

                    LDA     DoesPieceFitY           ; it does, increment y
                    STA     CurrentY
                    CLR     ForceDown
                    JMP     MainLoop
lockPiece           JSR     LockCurrentPiece
                    JSR     CheckForLines
                    LDA     HasLines
                    LBEQ    NewPiece                ; no lines
                    JSR     DrawField
                    LDB     #$ff
loopSleep           JSR     Sleep
                    DECB
                    BNE     loopSleep
                    JSR     RemoveLines

                    JMP     NewPiece
EndGame         JSR     GameOver
                BNE     exitGame
                JSR     InitField
                JSR     DrawField
                JMP     startNewGame
exitGame        JSR     RestoreVideoRAM               ; Cleanup and end execution
                RTS
***********************************************************************************************************************
* SaveVideoRam: saves the current video RAM into a buffer to be restored on exit                                      *
***********************************************************************************************************************
SaveVideoRAM    LDY     #VideoRAM               ; Y points to the beginning of the video ram
                LDX     VideoRAMBuffer          ; X points to the saved buffer video ram
LoopSaveVRAM    LDA     ,Y+                     ; Load in A the byte of video ram
                STA     ,X+                     ; And store it in the saved buffer
                CMPY    #EndVideoRAM            ; At the end of the video ram?
                BNE     LoopSaveVRAM
                RTS
VideoRAMBuffer  RMB     32*16                   ; 16 lines of 32 chars
***********************************************************************************************************************
* RestoreVideoRAM: restores the video ram from the buffer                                                             *
***********************************************************************************************************************
RestoreVideoRAM LDY     #VideoRAM               ; Y points to the beginning ot the video ram
                LDX     VideoRAMBuffer          ; X points to the saved buffer video ram
loopRestoreVRAM LDA     ,X+                     ; Load in A the saved video byte
                STA     ,Y+                     ; And put in in real video ram
                CMPY    #EndVideoRAM            ; At the end of the video ram?
                BNE     loopRestoreVRAM
                RTS
***********************************************************************************************************************
* ClsRight
***********************************************************************************************************************
ClsRight        PSHU    A,B,X,CC
                LDA     #$20                    ; space char
                LDX     #VideoRAM
loopClsRight0   LDB     #32-FieldWidth
                LEAX    FieldWidth,X
loopClsRight1   STA     ,X+
                DECB
                BNE     loopClsRight1
                CMPX    #EndVideoRAM
                BNE     loopClsRight0
                PULU    A,B,X,CC
                RTS
***********************************************************************************************************************
* PrintString: prints a non-inverted string ended with char '@'
*
* It substracts 64 to every char to display in non-inverted mode, which is why the end of line char is 64
*
* X:    Address of the string to display
* Y:    Video Address where it should be display
* Registers are restored on return
***********************************************************************************************************************
PrintString     PSHU    X,Y,CC
loopPrintString LDA     ,X+
                ANDA    #%00111111
                BEQ     endPrintString
                STA     ,Y+
                JMP     loopPrintString
endPrintString  PULU    X,Y,CC
                RTS
***********************************************************************************************************************
* DisplayIntro                                                                                                        *
* Registers are restored on return                                                                                    *
***********************************************************************************************************************
DisplayIntro    PSHU    X,Y,CC
                JSR     InitField
                JSR     DrawField
                JSR     ClsRight
                LDX     #IntroTitle
                LDY     #IntroTitleVRAM
                JSR     PrintString
                LDX     #Intro1
                LDY     #Intro1VRAM
                JSR     PrintString
                LDX     #Intro2
                LDY     #Intro2VRAM
                JSR     PrintString
                LDX     #Intro3
                LDY     #Intro3VRAM
                JSR     PrintString
                LDX     #Intro4
                LDY     #Intro4VRAM
                JSR     PrintString
                LDX     #Intro5
                LDY     #Intro5VRAM
                JSR     PrintString
                LDX     #Intro6
                LDY     #Intro6VRAM
                JSR     PrintString
                LDX     #Intro7
                LDY     #Intro7VRAM
                JSR     PrintString
                LDX     #Intro8
                LDY     #Intro8VRAM
                JSR     PrintString
                LDX     #IntroAK1
                LDY     #IntroAK1VRAM
                JSR     PrintString
                LDX     #IntroAK2
                LDY     #IntroAK2VRAM
                JSR     PrintString
diPollKeyboard  JSR     [POLCAT]                ; Polls keyboard
                BEQ     diPollKeyboard            ; No key pressed
                PULU    X,Y,CC
                RTS
***********************************************************************************************************************
* GameOver displays the final score and ask for a new game.
* Sets the zero flag of the CC register if the user wants a new game
* Other registers are restored on return
***********************************************************************************************************************
GameOver        PSHU    X,Y
                JSR     ClsRight                ; clears the right part of the screen
                LDX     #IntroTitle             ; display SPETRIS at the top
                LDY     #IntroTitleVRAM
                JSR     PrintString
                LDX     #GameOverTitle          ; display game over message
                LDY     #GameOverVRAM
                JSR     PrintString
                LDX     #FinalScore             ; display the final score
                LDY     #FinalScoreVRAM
                JSR     PrintString
                LDX     #AskNewGame             ; ask for a new game
                LDY     #AskNewGameVRAM
                JSR     PrintString
goPollKeyboard  JSR     [POLCAT]                ; polls keyboard
                BEQ     goPollKeyboard          ; no key pressed
                CMPA    #'Y'                    ; sets te zero flag to 1 if the key was Y
                PULU    X,Y
                RTS
***********************************************************************************************************************
* NewGame:                                                                                                           *
***********************************************************************************************************************
NewGame         PSHU    A,B,CC                  ; Save registers used in subroutine
                JSR     RandomizeSeed           ; Randomize the seed with the current timer
                CLR     QuitGame                ;
                LDD     #0                      ; Reset score
                STD     Score
                JSR     GetScoreStr             ; Reset score string
                CLR     SpeedCount
                LDA     #$FF
                STA     Speed
                JSR     InitField
                JSR     DrawField
                PULU    A,B,CC                  ; Restore registers used in subroutine
                RTS
***********************************************************************************************************************
* GetScoreStr: convert the integer Score into the string ScoreStr                                                                                                        *
*    D=Score
*    Stolen and adapted from Coco SDC-Explorer :)
***********************************************************************************************************************
GetScoreStr     PSHU	X,Y,A,B,CC              ;TODO why doesnt work with pshsu  ???
                LDX     #ScoreStr
                JSR	ITOA003
		PULU    X,Y,A,B,CC
		RTS
ITOA003		LDY 	#10000
	        JSR	ITOA000
	        LDY 	#1000
	        JSR	ITOA000
ITOA004		LDY	#100
		JSR	ITOA000
		LDY	#10
		JSR	ITOA000
		LDY	#1
ITOA000	        STD	NUMBER
	        STY	DIGIT
		LDA	#'0'
		STA	,X
ITOA001		LDD	NUMBER
		SUBD	DIGIT
		BCS	ITOA002
		STD	NUMBER
		LDA	,X
		INCA
		STA	,X
		JMP	ITOA001
ITOA002		CLRA
		LEAX	1,X
		STA	,X
		LDD 	NUMBER
        	RTS
NUMBER		FDB	0
DIGIT		FDB	0
***********************************************************************************************************************
* InitField:                                                                                                         *
***********************************************************************************************************************
InitField       PSHU    A,Y,CC
                LDY     #Field
                LDA     #ChSpc
ifLoopClear     STA     ,Y+
                CMPY    #FieldBottom
                BNE     ifLoopClear
                LDY     #Field
ifLoop0         LDA     #ChFieldLeft
                STA     ,Y
                LDA     #ChFieldRight
                STA     (FieldWidth-1),Y
                LEAY    FieldWidth,Y
                CMPY    #FieldBottom
                BNE     ifLoop0
                PULU    A,Y,CC
                RTS
***********************************************************************************************************************
* RandomizeSeed:                                                                                                      *
***********************************************************************************************************************
RandomizeSeed   PSHS    D,U
                LDD     $112                    ; timer value
                JSR     $B4F4                   ; put TIMER into FPAC 0 for max value
                JSR     $BF1F                   ; generate a random number THIS MODIFIES U!!!
                JSR     $B3ED                   ;retrieve FPAC 0; D= your random number
                STB     $118                    ; seed location
                PULS    D,U
                RTS
***********************************************************************************************************************
* DrawField:                                                                                                          *
***********************************************************************************************************************
DrawField       PSHU    A,B,X,Y,CC
                LDY     #VideoRAM               ; Y points to the real video ram
                LDX     #Field                  ; X points to the intro text
dfLoop1         LDB     #FieldWidth
dfLoop2         LDA     ,X+                     ; Load in A the byte to display
                STA     ,Y+                     ; Put A in video ram
                DECB                            ; Decrement counter of chars to display
                BNE     dfLoop2                 ; Loop if more to display for this row
                LEAY    32-FieldWidth,Y
                CMPY    #EndVideoRAM            ; End of video ram?
                BNE     dfLoop1                 ; Loop if more to display
                PULU    A,B,X,Y,CC
                RTS



********************************************************************************
_DoesPieceFitCK     MACRO
                    STD     DoesPieceFitX
                    LDA     CurrentY
                    STA     DoesPieceFitY
                    LDA     CurrentRotation
                    STA     DoesPieceFitR
                    JSR     DoesPieceFit
                    LDA     PieceFitFlag
                    LBEQ    endCheckKeyboard
                    ENDM
*******************************************************************************
CheckKeyboard       CMPA    #KeyLeft                ; left
                    BEQ     PressLeft
                    CMPA    #KeyRight               ; right
                    BEQ     PressRight
                    CMPA    #KeyUp                  ; Up
                    BEQ     PressUp
                    CMPA    #KeyDown                  ; Down
                    LBEQ    PressDown
                    CMPA    #KeySpace               ; Spacebar
                    LBEQ    PressSpc
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
PressDown           LDD     CurrentX
                    STD     DoesPieceFitX
                    LDA     CurrentY
                    INCA
                    STA     DoesPieceFitY
                    LDA     CurrentRotation
                    STA     DoesPieceFitR
                    JSR     DoesPieceFit
                    LDA     PieceFitFlag
                    BEQ     endCheckKeyboard
                    INC     CurrentY
                    INC     HasToDraw
                    JMP     endCheckKeyboard
PressSpc            INC     Falling
                    JMP     endCheckKeyboard
PressBrk            INC     QuitGame
endCheckKeyboard    RTS
*******************************************************************************
GetNextPiece        PSHU    A,B,CC
                    CLR     Falling
                    LDA     NextPiece
                    STA     CurrentPiece
                    INC     HasToDraw
                    LDD     #(FieldWidth/2)-2
                    STD     CurrentX
                    CLR     CurrentY
                    LDD     #7                      ; random number from 1 to 7
                    JSR     $B4F4                   ;copy D into FPAC 0 (Floating point accumulator)
                    JSR     $BF1F                   ;generate a random number
                    JSR     $B3ED                   ;retrieve FPAC 0; D= your random number
                    DECB                            ; dec 1 because number is between 1 and 7
                    STB     NextPiece
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
                    LDY     #NextPieceVRAM
                    LDA     NextPiece               ; compute the offset in the pieces struct array
                    LDB     #PieceStructLen
                    MUL
                    ADDD    #Pieces                 ; add base pointer
                    TFR     D,X                     ; X now points to the beginning of the piece struct to draw
dnpLoopRow0         LDB     #4                      ; 4 "pixels' per row
dnpLoopRow1         LDA     ,X+
                    CMPA    #Dot
                    BNE     dnpDraw                 ; not a dot, we draw it on screen then
                    LDA     #ChSpc
                    JMP     dnpEndDraw
dnpDraw             LDA     dnpDrawChar             ; the char to draw, from the stack
dnpEndDraw          STA     ,Y+
                    DECB
                    BNE     dnpLoopRow1
                    CMPY    #NextPieceEndVRAM          ; are we done drawing?
                    BGE     dnpEnd
                    LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                    JMP     dnpLoopRow0
dnpEnd              PULU    A,B,X,Y,CC              ; restore the registers
                    RTS
dnpDrawChar         FCB     0
*******************************************************************************
DrawInfo        PSHU    X,Y,CC
                JSR     ClsRight
                LDX     #ScoreLabel
                LDY     #ScoreLabelVRAM
                JSR     PrintString
                LDX     #NextPieceLabel
                LDY     #NextPieceLabelVRAM
                JSR     PrintString
                PULU    X,Y,CC
                RTS
*******************************************************************************
DisplayScore        LDX     #ScoreStr
                    LDY     #ScoreVRAM
                    LDB     #5
lpDisplayScore      LDA     ,X+
                    STA     ,Y+
                    DECB
                    BNE     lpDisplayScore
                    RTS
*******************************************************************************
Sleep               PSHU    A,CC
                    LDA     #SleepTime
sleepLoop           DECA
                    BNE     sleepLoop
                    PULU    A,CC
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
CheckForLines       PSHU    A,B,X,Y,CC
                    CLR     HasLines
                    LDX     #Field
cflCheckLine        LDB     #FieldWidth-2
cflLoop0            LDA     B,X
                    CMPA    #ChSpc
                    BEQ     cflNextLine
                    DECB
                    BNE     cflLoop0
                    INC     HasLines
                    LDD     Score
                    ADDD    #1
                    STD     Score
                    JSR     GetScoreStr
                    LDB     #FieldWidth-2
                    LDA     #ChLine
cflLoop1            STA     B,X
                    DECB
                    BNE     cflLoop1
cflNextLine         LEAX    FieldWidth,X
                    CMPX    #FieldBottom
                    BLT     cflCheckLine
                    PULU    A,B,X,Y,CC
                    RTS
*******************************************************************************
RemoveLines         PSHU    A,B,X,Y,CC
                    LDX     #FieldBottom-FieldWidth
rlLoop0             LDA     1,X
                    CMPA    #ChLine
                    BNE     rl2
                    JSR     moveLines
                    JMP     rlLoop0
rl2                 LEAX    -FieldWidth,X
                    CMPX    #Field
                    BGE     rlLoop0
endRemoveLines      PULU    A,B,X,Y,CC
                    RTS

moveLines           PSHS    X
mlLoop0             CMPX    #Field
                    BEQ     endMoveLines
                    LEAY    -FieldWidth,X
                    LDB     #FieldWidth-2
mlLoop1             LDA     B,Y
                    STA     B,X
                    DECB
                    BNE     mlLoop1
                    TFR     Y,X
                    JMP     mlLoop0
endMoveLines        PULS    X
                    RTS

***********************************************************************************************************************
***********************************************************************************************************************
***********************************************************************************************************************
FieldWidth      EQU     12
Field           RMB     FieldWidth*16
FieldBottom     FCC     /############/





*******************************************************************************
Dot                 EQU     $2E
VideoRAM            EQU     $400                    ; video ram address
EndVideoRAM         EQU     $600
POLCAT	            EQU	    $A000	                ; read keyboard ROM routine
ChSpc               EQU     128 ;+(16*0)+15
ChFieldLeft         EQU     128+(16*0)+5
ChFieldRight        EQU     128+(16*0)+10
ChLine              EQU     61
SleepTime           EQU     $FF
KeyUp		        EQU	    $5E		                ; UP key
KeyDown		        EQU 	$0A		                ; DOWN key
KeyLeft             EQU     $08
KeyRight            EQU     $09
KeyEscape           EQU     $03                     ; Break
KeySpace            EQU     $20

*******************************************************************************
Score               FDB     0
ScoreStr            RMB     16
CurrentX            FDB     0
CurrentY            FCB     0
CurrentPiece        FCB     0
NextPiece           FCB     0
CurrentRotation     FCB     0
ForceDown           FCB     0
Speed               FCB     0
SpeedCount          FCB     0
HasToDraw           FCB     0
DoesPieceFitX       FDB     0
DoesPieceFitY       FCB     0
DoesPieceFitR       FCB     0
PieceFitFlag        FCB     0
QuitGame            FCB     0
HasLines            FCB     0
Falling             FCB     0
*******************************************************************************
PiecesColor         FCB     128+15+(16*7)           ; color piece 1
                    FCB     128+15+16               ; color piece 2
                    FCB     128+15+(16*2)           ; color piece 3
                    FCB     128+15+(16*3)           ; Color piece 4
                    FCB     128+15+(16*4)           ; Color piece 5
                    FCB     128+15+(16*5)           ; Color piece 6
                    FCB     128+15+(16*6)           ; Color piece 7
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
IntroTitle      FCC     /SPETRIS!@/
IntroTitleVRAM  EQU     VideoRAM+FieldWidth+6
Intro1          FCC     /USE THE LEFT, RIGHT@/
Intro2          FCC     /AND DOWN ARROW KEYS@/
Intro3          FCC     /TO MOVE THE PIECE.@/
Intro4          FCC     /USE THE UP ARROW@/
Intro5          FCC     /KEY TO ROTATE, THE@/
Intro6          FCC     /SPACEBAR KEY TO@/
Intro7          FCC     /DROP AND THE P KEY@/
Intro8          FCC     /TO PAUSE THE GAME.@/
IntroAK1        FCC     /PRESS ANY KEY@/
IntroAK2        FCC     /TO START GAME@/
Intro1VRAM      EQU     VideoRAM+(32*2)+FieldWidth+1
Intro2VRAM      EQU     VideoRAM+(32*3)+FieldWidth+1
Intro3VRAM      EQU     VideoRAM+(32*4)+FieldWidth+1
Intro4VRAM      EQU     VideoRAM+(32*6)+FieldWidth+1
Intro5VRAM      EQU     VideoRAM+(32*7)+FieldWidth+1
Intro6VRAM      EQU     VideoRAM+(32*8)+FieldWidth+1
Intro7VRAM      EQU     VideoRAM+(32*9)+FieldWidth+1
Intro8VRAM      EQU     VideoRAM+(32*10)+FieldWidth+1
IntroAK1VRAM    EQU     VideoRAM+(32*13)+FieldWidth+4
IntroAK2VRAM    EQU     VideoRAM+(32*14)+FieldWidth+4
GameOverTitle   FCC     /GAME OVER :(@/
FinalScore      FCC     /FINAL SCORE:@/
AskNewGame      FCC     \NEW GAME? Y/N@\
GameOverVRAM    EQU     VideoRAM+(32*3)+FieldWidth+1
FinalScoreVRAM  EQU     VideoRAM+(32*5)+FieldWidth+1
AskNewGameVRAM  EQU     VideoRAM+(32*7)+FieldWidth+1
ScoreLabel          FCC     /SCORE:@/
ScoreLabelVRAM      EQU     VideoRAM+FieldWidth+2
ScoreVRAM           EQU     VideoRAM+FieldWidth+2+7
NextPieceLabel      FCC     /NEXT PIECE:@/
NextPieceLabelVRAM  EQU     VideoRAM+(32*2)+FieldWidth+2
NextPieceVRAM       EQU     VideoRAM+(32*4)+FieldWidth+2
NextPieceEndVRAM    EQU     VideoRAM+(32*8)+FieldWidth+6

UserStack           EQU     *
                    END     Start
