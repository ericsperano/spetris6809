*======================================================================================================================
* Spétris                                                                                                             
*
* Tetris Clone for the Color Computer
* First attempt to 6809 assembler by github.com/ericsperano (2019)
*
* TODO PieceCount to increment speed
*----------------------------------------------------------------------------------------------------------------------
                ORG     $3F00
_HRF            MACRO                           ; HasRoundFlag: macro to check if a round flag is set
                LDA     RoundFlags
                ANDA    \1
                ENDM 
_SRF            MACRO                           ; SetRoundFlag: macro to set a round flag to 1
                LDA     RoundFlags
                ORA     \1
                STA     RoundFlags
                ENDM         
_RRF            MACRO                           ; ResetRoundFlag: macro to set a round flag to 0
                LDA     RoundFlags
                COMA
                ORA     \1
                COMA
                STA     RoundFlags
                ENDM                
*----------------------------------------------------------------------------------------------------------------------
SPETRIS         LDU     #UserStack              ; init user stack pointer
                JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     RandomizeSeed           ; randomize the seed with the current timer
                JSR     DisplayIntro            ; display the intro message and wait for a key to be pressed
startGame       JSR     NewGame                 ; initialize new game data and screen
startRound      JSR     NewRound                ; initialize this round (a round is what handle one piece in the game)
                LDD     CurrentX                   ; first check if it would fit
                STD     DoesPieceFitX
                LDA     CurrentY
                STA     DoesPieceFitY
                LDA     CurrentRotation
                STA     DoesPieceFitR
                JSR     DoesPieceFit
                LDA     PieceFitFlag
                LBEQ    endGame
roundLoop       _HRF    #FRefreshScreen         ; zero flag will be set if flag is disabled
                BEQ     sleep                   ; zero flag unset: no screen refresh needed
                JSR     DrawField
                JSR     DrawCurrPiece
                LDY     #ScoreVRAM
                JSR     DisplayScore
                _RRF    #FRefreshScreen
sleep           _HRF    #FFalling
                BEQ     sleep1
                _SRF    #FForceDown
                _SRF    #FRefreshScreen
sleep1          JSR     Sleep                   ; increment the speed count
                INC     SpeedCount
                LDA     SpeedCount              ; and force down if it reached speed max
                CMPA    Speed
                BNE     pollKeyboard           ; if not go straight to poll keyboard
                _SRF    #FForceDown
                _SRF    #FRefreshScreen
                CLR     SpeedCount
pollKeyboard    JSR     [POLCAT]                ; Polls keyboard
                BEQ     chkForceDown            ; No key pressed
                JSR     CheckKeyboard
                _HRF     #FQuitGame
                BNE      exitGame
chkForceDown    _HRF    #FForceDown
                BEQ     roundLoop
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
                _RRF    #FForceDown
                JMP     roundLoop
lockPiece       JSR     LockPiece
                JSR     CheckForLines
                _HRF    #FHasLines
                LBEQ    startRound
                JSR     DrawField
                LDB     #$ff
loopSleep       JSR     Sleep
                DECB
                BNE     loopSleep
                JSR     RemoveLines
                JMP     startRound
endGame         JSR     GameOver                ; game over message, zero flag is set if a new game is requested
                BNE     exitGame                
                JSR     InitField               ; clear the field
                JSR     DrawField               ; (init and drawfield were done in display intro)
                JMP     startGame               ; and go back to game initialization
exitGame        JSR     RestoreVideoRAM         ; restore video ram
                RTS
*======================================================================================================================
* SaveVideoRam: saves the current video RAM into a buffer to be restored on exit                                      
*----------------------------------------------------------------------------------------------------------------------
SaveVideoRAM    PSHU    A,X,Y,CC                ; save registers
                LDY     #VideoRAM               ; Y points to the beginning of the video ram
                LDX     VideoRAMBuffer          ; X points to the saved buffer video ram
LoopSaveVRAM    LDA     ,Y+                     ; Load in A the byte of video ram
                STA     ,X+                     ; And store it in the saved buffer
                CMPY    #EndVideoRAM            ; At the end of the video ram?
                BNE     LoopSaveVRAM
                PULU    A,X,Y,CC                ; restore registers
                RTS
VideoRAMBuffer  RMB     32*16                   ; 16 lines of 32 chars
*======================================================================================================================
* RestoreVideoRAM: restores the video ram from the buffer                                                             
*----------------------------------------------------------------------------------------------------------------------
RestoreVideoRAM PSHU    A,X,Y,CC                ; save registers
                LDY     #VideoRAM               ; Y points to the beginning of the video ram
                LDX     VideoRAMBuffer          ; X points to the saved buffer video ram
loopRestoreVRAM LDA     ,X+                     ; Load in A the saved video byte
                STA     ,Y+                     ; And put in in real video ram
                CMPY    #EndVideoRAM            ; At the end of the video ram?
                BNE     loopRestoreVRAM
                PULU    A,X,Y,CC                ; restore registers
                RTS
*======================================================================================================================
* PrintString: prints a string in non-inverted video at a specified video address.
*
* X (read):     Points to a displayable string structure:
*               bytes  0      2    3   ... n   n+1  
*                      +---+---+---+---+---+---+
*                      | VRAM  | String    | @ |
*                      +---+---+---+---+---+---+
*               First two bytes is the address where the string should be written, then it is a variable length
*               string and the end of string character is '@'. It substracts 64 to every char so it is displayed
*               in non-inverted mode. ('@' - 64 == 0)
*----------------------------------------------------------------------------------------------------------------------
PrintString     PSHU    X,Y,CC                  ; save registers
                LEAY    [,X++]                  ; load the first two bytes in Y and advance X to start of string
loopPS          LDA     ,X+                     ; load char from string         
                ANDA    #%00111111              ; keep the right 6 bits
                BEQ     endPS                   ; exit loop if char is end of string 
                STA     ,Y+                     ; display it
                JMP     loopPS                  ; and loop
endPS           PULU    X,Y,CC                  ; restore registers
                RTS
*======================================================================================================================
* ClsRight: clear the right side of the screen and print the game name at the top
*----------------------------------------------------------------------------------------------------------------------
ClsRight        PSHU    A,B,X,CC                ; save registers
                LDA     #KeySpace               ; char to clear the screen
                LDX     #VideoRAM               ; x points to the beginning of the video ram
loopClsRight0   LDB     #32-FieldWidth          ; number of cols on the right side of the field
                LEAX    FieldWidth,X            ; move x to the right side of the field
loopClsRight1   STA     ,X+                     ; put the char on screen
                DECB
                BNE     loopClsRight1           ; haven't reach the end of the line
                CMPX    #EndVideoRAM            ; check if we are done completely
                BNE     loopClsRight0
                LDX     #GameTitle              ; load in x the displayable game title
                JSR     PrintString             ; print it
                PULU    A,B,X,CC                ; restore registers
                RTS
*======================================================================================================================
* InitField:                                                                                                         
*----------------------------------------------------------------------------------------------------------------------
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
*======================================================================================================================
* DrawField:                                                                                                          
*----------------------------------------------------------------------------------------------------------------------
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
*======================================================================================================================
* DisplayIntro:                                                                                                       
*----------------------------------------------------------------------------------------------------------------------
DisplayIntro    PSHU    X,Y,CC                  ; save registers
                JSR     InitField               ; display an empty field to the left
                JSR     DrawField
                JSR     ClsRight                ; clear the right side and print the game title
                LDX     #Intro1                 ; print the intro strings
                JSR     PrintString
                LDX     #Intro2
                JSR     PrintString
                LDX     #Intro3
                JSR     PrintString
                LDX     #Intro4
                JSR     PrintString
                LDX     #Intro5
                JSR     PrintString
                LDX     #Intro6
                JSR     PrintString
                LDX     #Intro7
                JSR     PrintString
                LDX     #Intro8
                JSR     PrintString
                LDX     #IntroAK1               ; print the press any key message
                JSR     PrintString
                LDX     #IntroAK2
                JSR     PrintString
diPollKeyboard  JSR     [POLCAT]                ; polls keyboard for any key
                BEQ     diPollKeyboard          ; poll again if no key pressed
                PULU    X,Y,CC                  ; restore registers
                RTS
*======================================================================================================================
* RandomizeSeed:                                                                                                      
*----------------------------------------------------------------------------------------------------------------------
RandomizeSeed   PSHS    A,B,U                   ; save registers on the system stack
                LDD     $112                    ; timer value
                JSR     $B4F4                   ; put TIMER into FPAC 0 for max value
                JSR     $BF1F                   ; generate a random number THIS MODIFIES U!!!
                JSR     $B3ED                   ; retrieve FPAC 0; D= your random number
                STB     $118                    ; seed location
                PULS    A,B,U                   ; restore registers from the system stack
                RTS
*======================================================================================================================
* NewGame: initializes the variables for a new game, prepares the field and do an initial drawing of the screen 
*----------------------------------------------------------------------------------------------------------------------
NewGame         PSHU    A,B,CC                  ; save registers
                LDD     #0                      ; reset score
                STD     Score
                JSR     GetScoreStr             ; reset score string
                CLR     SpeedCount
                LDA     #$FF                    ; reset speed
                STA     Speed
                JSR     InitField               ; initialize field
                JSR     DrawField               ; display the field on the left
                PULU    A,B,CC                  ; restore registers 
                JSR     ClsRight                ; clear the right side and print the game title
                LDX     #ScoreLabel             ; display the score label
                JSR     PrintString
                LDX     #NextPieceLabel         ; display the next piece lable
                JSR     PrintString
                JSR     GetNextPiece            ; initialize next piece
                RTS
*======================================================================================================================
* GetNextPiece:
*----------------------------------------------------------------------------------------------------------------------
GetNextPiece    PSHS    A,B,U,CC                ; save registers on the system stack
                LDA     NextPiece
                STA     CurrentPiece
                LDD     #(FieldWidth/2)-2
                STD     CurrentX
                CLR     CurrentY
                LDD     #7                      ; random number from 1 to 7
                JSR     $B4F4                   ; copy D into FPAC 0 (Floating point accumulator)
                JSR     $BF1F                   ; generate a random number
                JSR     $B3ED                   ; retrieve FPAC 0; D= your random number
                DECB                            ; decrement by 1 because number is between 1 and 7
                STB     NextPiece
                PULS    A,B,U,CC                ; restore registers from the system stack
                RTS
*======================================================================================================================
* DrawNextPiece:
*----------------------------------------------------------------------------------------------------------------------
DrawNextPiece   PSHU    A,B,X,Y,CC
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
dnpLoopRow0     LDB     #4                      ; 4 "pixels' per row
dnpLoopRow1     LDA     ,X+
                CMPA    #ChDot
                BNE     dnpDraw                 ; not a dot, we draw it on screen then
                LDA     #ChSpc
                JMP     dnpEndDraw
dnpDraw         LDA     dnpDrawChar             ; the char to draw, from the stack
dnpEndDraw      STA     ,Y+
                DECB
                BNE     dnpLoopRow1
                CMPY    #NextPieceVRAME          ; are we done drawing?
                BGE     dnpEnd
                LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                JMP     dnpLoopRow0
dnpEnd          PULU    A,B,X,Y,CC              ; restore the registers
                RTS
dnpDrawChar     FCB     0
*======================================================================================================================
* NewRound: initialize a new round by setting up the flags and getting a new piece
* RoundFlags (w)        cleared, then set to refresh the screen
*----------------------------------------------------------------------------------------------------------------------
NewRound        CLR     RoundFlags              ; clear the flags for this round
                _SRF    #FRefreshScreen         ; will refresh screen at the start of this round
                JSR     GetNextPiece
                JSR     DrawNextPiece
                RTS
*======================================================================================================================
* Sleep:
*----------------------------------------------------------------------------------------------------------------------
Sleep           PSHU    A,CC
                LDA     #SleepTime
sleepLoop       DECA
                BNE     sleepLoop
                PULU    A,CC
                RTS
*======================================================================================================================
* GameOver: displays the final score and ask for a new game
*
* CC (w)        Sets the zero flag if the user wants a new game
*----------------------------------------------------------------------------------------------------------------------
GameOver        PSHU    X,Y
                JSR     ClsRight                ; clears the right part of the screen
                LDX     #GameOverLabel          ; display game over message
                JSR     PrintString
                LDX     #FinalScoreLabel        ; display the final score label
                JSR     PrintString
                LDY     #FinalScoreVRAM
                JSR     DisplayScore
                LDX     #AskNewGameLabel        ; ask for a new game
                JSR     PrintString
goPollKeyboard  JSR     [POLCAT]                ; polls keyboard
                BEQ     goPollKeyboard          ; no key pressed
                CMPA    #'Y'                    ; sets the zero flag if the key was Y
                BEQ     endGameOver             ; end exit
                CMPA    #'N'                    ; poll again if key was not N
                BNE     goPollKeyboard  
                LDA     #1                      ; unset the zero flag for N key
endGameOver     PULU    X,Y
                RTS









***********************************************************************************************************************
* GetScoreStr: convert the integer Score into the string ScoreStr                                                                
*    D=Score
*    Stolen and adapted from Coco SDC-Explorer :)
***********************************************************************************************************************
GetScoreStr     PSHU	X,Y,A,B,CC              ;TODO why doesnt work with pshsu  ???
                LDX     #ScoreStr
                JSR	ITOA003
                LDX     #ScoreStr
                LDB     #KeySpace
trimZeros       LDA     ,X
                CMPA    #'0'
                BNE     gssEnd          
                STB     ,X+
                JMP     trimZeros
gssEnd		PULU    X,Y,A,B,CC
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
********************************************************************************
_DoesPieceFitCK MACRO
                STD     DoesPieceFitX
                LDA     CurrentY
                STA     DoesPieceFitY
                LDA     CurrentRotation
                STA     DoesPieceFitR
                JSR     DoesPieceFit
                LDA     PieceFitFlag
                LBEQ    endCK
                ENDM
*******************************************************************************
CheckKeyboard   CMPA    #KeyLeft                ; left
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
                JMP     endCK         ; ignore other keys
PressLeft       LDD     CurrentX
                DECB
                _DoesPieceFitCK
                DEC     CurrentX+1
                _SRF    #FRefreshScreen
                JMP     endCK
PressRight      LDD     CurrentX
                INCB
                _DoesPieceFitCK
                INC     CurrentX+1
                _SRF    #FRefreshScreen
                JMP     endCK
PressUp         LDA     CurrentRotation         ; KeyUp! Increment rotation
                INCA
                CMPA    #4                      ; or reset to 0 if == 4
                BNE     pressUpEnd
                CLRA
pressUpEnd      STA     DoesPieceFitR
                LDD     CurrentX
                STD     DoesPieceFitX
                LDA     CurrentY
                STA     DoesPieceFitY
                JSR     DoesPieceFit
                LDA     PieceFitFlag
                BEQ     endCK
                LDA     DoesPieceFitR
                STA     CurrentRotation
                _SRF    #FRefreshScreen
                JMP     endCK
PressDown       LDD     CurrentX
                STD     DoesPieceFitX
                LDA     CurrentY
                INCA
                STA     DoesPieceFitY
                LDA     CurrentRotation
                STA     DoesPieceFitR
                JSR     DoesPieceFit
                LDA     PieceFitFlag
                BEQ     endCK
                INC     CurrentY
                _SRF    #FRefreshScreen
                JMP     endCK
PressSpc        _SRF    #FFalling
                JMP     endCK
PressBrk        _SRF    #FQuitGame
endCK           RTS
*******************************************************************************
*******************************************************************************
DrawCurrPiece   PSHU    A,B,X,Y,CC
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
dcpLoopRow0     LDB     #4                      ; 4 "pixels' per row
dcpLoopRow1     LDA     ,X+
                CMPA    #ChDot
                BNE     dcpDraw                 ; not a dot, we draw it on screen then
                LEAY    1,Y                     ; won't draw but still need to move to next pos on screen
                JMP     dcpEndDraw
dcpDraw         LDA     dcpDrawChar             ; the char to draw, from the stack
                STA     ,Y+
dcpEndDraw      DECB
                BNE     dcpLoopRow1
                CMPY    dcpDrawEndAddr          ; are we done drawing?
                BGE     dcpEnd
                LEAY    28,Y                    ; move at the beginning of next line on video ram (32-width=28)
                JMP     dcpLoopRow0
dcpEnd          PULU    A,B,X,Y,CC              ; restore the registers
                RTS
dcpDrawChar     FCB     0
dcpDrawEndAddr  FDB     0
*******************************************************************************
* Y: address to display
DisplayScore    PSHU    A,B,X,Y,CC
                LDX     #ScoreStr
                LDB     #5
lpDisplayScore  LDA     ,X+
                STA     ,Y+
                DECB
                BNE     lpDisplayScore
                LDA     #'0'
                STA     ,Y
                PULU    A,B,X,Y,CC
                RTS
*******************************************************************************
DoesPieceFit    PSHU    Y,X,A,B,CC
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
dpfLoopRow0     LDB     #4                      ; 4 "pixels' per row
dpfLoopRow1     LDA     ,X+
                CMPA    #ChDot
                BNE     dpfCheck                ; not a dot, we must check
                LEAY    1,Y                     ; won't check but still need to move to next pos on the field
                JMP     dpfEndCheck
dpfCheck        LDA     ,Y+                     ; the char to draw, from the stack
                CMPA    #ChSpc
                BEQ     dpfEndCheck
                CLR     PieceFitFlag            ; piece does not fit
                JMP     dpfEnd
dpfEndCheck     DECB
                BNE     dpfLoopRow1
                CMPY    dpfFieldEndAddr         ; are we done checking?
                BGE     dpfEnd
                LEAY    (FieldWidth-4),Y        ; move at the beginning of next line on video ram (32-width=28)
                JMP     dpfLoopRow0
dpfEnd          PULU    Y,X,A,B,CC              ; restore the registers
                RTS
dpfFieldEndAddr FDB     0
*******************************************************************************
LockPiece       PSHU    Y,X,A,B,CC
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
lcpLoopRow0     LDB     #4                      ; 4 "pixels' per row
lcpLoopRow1     LDA     ,X+
                CMPA    #ChDot
                BNE     lcpLock                 ; not a dot, we must check
                LEAY    1,Y                     ; won't check but still need to move to next pos on the field
                JMP     lcpEndLock
lcpLock         LDA     lcpDrawChar
                STA     ,Y+
lcpEndLock      DECB
                BNE     lcpLoopRow1
                CMPY    lcpFieldEndAddr         ; are we done checking?
                BGE     lcpEnd
                LEAY    (FieldWidth-4),Y        ; move at the beginning of next line on video ram (32-width=28)
                JMP     lcpLoopRow0
lcpEnd          PULU    Y,X,A,B,CC              ; restore the registers
                RTS
lcpDrawChar     FCB     0
lcpFieldEndAddr FDB     0
*******************************************************************************
CheckForLines   PSHU    A,B,X,Y,CC
                _RRF    #FHasLines        
*                CLR     HasLines
                LDX     #Field
cflCheckLine    LDB     #FieldWidth-2
cflLoop0        LDA     B,X
                CMPA    #ChSpc
                BEQ     cflNextLine
                DECB
                BNE     cflLoop0
                _SRF    #FHasLines
*                INC     HasLines
                LDD     Score
                ADDD    #1
                STD     Score
                JSR     GetScoreStr
                LDB     #FieldWidth-2
                LDA     #ChLine
cflLoop1        STA     B,X
                DECB
                BNE     cflLoop1
cflNextLine     LEAX    FieldWidth,X
                CMPX    #FieldBottom
                BLT     cflCheckLine
                PULU    A,B,X,Y,CC
                RTS
*******************************************************************************
RemoveLines     PSHU    A,B,X,Y,CC
                LDX     #FieldBottom-FieldWidth
rlLoop0         LDA     1,X
                CMPA    #ChLine
                BNE     rl2
                JSR     moveLines
                JMP     rlLoop0
rl2             LEAX    -FieldWidth,X
                CMPX    #Field
                BGE     rlLoop0
endRemoveLines  PULU    A,B,X,Y,CC
                RTS

moveLines       PSHS    X
mlLoop0         CMPX    #Field
                BEQ     endMoveLines
                LEAY    -FieldWidth,X
                LDB     #FieldWidth-2
mlLoop1         LDA     B,Y
                STA     B,X
                DECB
                BNE     mlLoop1
                TFR     Y,X
                JMP     mlLoop0
endMoveLines    PULS    X
                RTS

*======================================================================================================================
* Field structure and constants
*----------------------------------------------------------------------------------------------------------------------
FieldWidth      EQU     12
Field           RMB     FieldWidth*16
FieldBottom     FCC     /############/
*======================================================================================================================
* Game constants and variables
*----------------------------------------------------------------------------------------------------------------------
Score           FDB     0
NextPiece       FCB     0
SleepTime       EQU     $FF
VideoRAM        EQU     $400                    ; video ram address
EndVideoRAM     EQU     $600
POLCAT	        EQU	$A000	                ; read keyboard ROM routine
*======================================================================================================================
* Game round variables
*----------------------------------------------------------------------------------------------------------------------
CurrentPiece    FCB     0
RoundFlags      FCB     0
FRefreshScreen  EQU     %00000001
FPieceFits      EQU     %00000010
FForceDown      EQU     %00000100
FFalling        EQU     %00001000
FHasLines       EQU     %00010000
FQuitGame       EQU     %00100000
*======================================================================================================================
* Char constants
*----------------------------------------------------------------------------------------------------------------------
ChSpc           EQU     128 
ChFieldLeft     EQU     128+(16*0)+5
ChFieldRight    EQU     128+(16*0)+10
ChLine          EQU     $2A
ChDot           EQU     $2E
*======================================================================================================================
* Key constants
*----------------------------------------------------------------------------------------------------------------------
KeyUp		EQU	$5E
KeyDown		EQU 	$0A		               
KeyLeft         EQU     $08
KeyRight        EQU     $09
KeyEscape       EQU     $03                     ; Break
KeySpace        EQU     $20



*******************************************************************************
ScoreStr        RMB     16
CurrentX        FDB     0
CurrentY        FCB     0
CurrentRotation FCB     0
Speed           FCB     0
SpeedCount      FCB     0
DoesPieceFitX   FDB     0
DoesPieceFitY   FCB     0
DoesPieceFitR   FCB     0
PieceFitFlag    FCB     0
*======================================================================================================================
* Pieces colors and shapes
*----------------------------------------------------------------------------------------------------------------------
PiecesColor     FCB     128+15+(16*7)           ; color piece 1
                FCB     128+15+16               ; color piece 2
                FCB     128+15+(16*2)           ; color piece 3
                FCB     128+15+(16*3)           ; Color piece 4
                FCB     128+15+(16*4)           ; Color piece 5
                FCB     128+15+(16*5)           ; Color piece 6
                FCB     128+15+(16*6)           ; Color piece 7
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
*======================================================================================================================
* Displayable strings
*----------------------------------------------------------------------------------------------------------------------
GameTitle       FDB     VideoRAM+FieldWidth+7
                FCC     /SPETRIS!@/
Intro1          FDB     VideoRAM+(32*2)+FieldWidth+1
                FCC     /USE THE LEFT, RIGHT@/
Intro2          FDB     VideoRAM+(32*3)+FieldWidth+1
                FCC     /AND DOWN ARROW KEYS@/
Intro3          FDB     VideoRAM+(32*4)+FieldWidth+1
                FCC     /TO MOVE THE PIECE.@/
Intro4          FDB     VideoRAM+(32*6)+FieldWidth+1
                FCC     /USE THE UP ARROW@/
Intro5          FDB     VideoRAM+(32*7)+FieldWidth+1
                FCC     /KEY TO ROTATE, THE@/
Intro6          FDB     VideoRAM+(32*8)+FieldWidth+1
                FCC     /SPACEBAR KEY TO@/
Intro7          FDB     VideoRAM+(32*9)+FieldWidth+1
                FCC     /DROP AND THE P KEY@/
Intro8          FDB     VideoRAM+(32*10)+FieldWidth+1
                FCC     /TO PAUSE THE GAME.@/
IntroAK1        FDB     VideoRAM+(32*13)+FieldWidth+4
                FCC     /PRESS ANY KEY@/
IntroAK2        FDB     VideoRAM+(32*14)+FieldWidth+4
                FCC     /TO START GAME@/
ScoreLabel      FDB     VideoRAM+(32*3)+FieldWidth+1
                FCC     /SCORE:@/
ScoreVRAM       EQU     VideoRAM+(32*3)+FieldWidth+7
NextPieceLabel  FDB     VideoRAM+(32*5)+FieldWidth+1
                FCC     /NEXT PIECE:@/
NextPieceVRAM   EQU     VideoRAM+(32*7)+FieldWidth+1
NextPieceVRAME  EQU     VideoRAM+(32*11)+FieldWidth+1+4
GameOverLabel   FDB     VideoRAM+(32*4)+FieldWidth+1+4
                FCC     /GAME OVER :(@/
FinalScoreLabel FDB     VideoRAM+(32*7)+FieldWidth+1+4
                FCC     /FINAL SCORE:@/
FinalScoreVRAM  EQU     VideoRAM+(32*9)+FieldWidth+1+7
AskNewGameLabel FDB     VideoRAM+(32*13)+FieldWidth+1+3
                FCC     \NEW GAME? Y/N@\                
*======================================================================================================================
* User stack (end of program)
*----------------------------------------------------------------------------------------------------------------------
                RMB     64                              ; user stack space TODO maybe even less????
UserStack       EQU     *                               ; have the user stack at the end of the program
                END     SPETRIS