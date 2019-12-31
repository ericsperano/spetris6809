*======================================================================================================================
* Spétris
*
* Tetris Clone for the Color Computer
* First attempt to 6809 assembler by github.com/ericsperano (2019)
*
* Based on this excellent tutorial on how to write a text mode Tetris clone in C++:
* https://github.com/OneLoneCoder/videos/blob/master/OneLoneCoder_Tetris.cpp
* https://www.youtube.com/watch?v=8OK8_tHeCIA
*----------------------------------------------------------------------------------------------------------------------
                ORG     $3F00
; has round flag macro
_HRF            MACRO
                LDA     RoundFlags
                ANDA    \1
                ENDM
; set round flag macro
_SRF            MACRO
                LDA     RoundFlags
                ORA     \1
                STA     RoundFlags
                ENDM
; clear round flag macro
_CRF            MACRO
                LDA     RoundFlags
                COMA
                ORA     \1
                COMA
                STA     RoundFlags
                ENDM
; draw scores macro
_DRSCRS         MACRO
                LDX     #ScoreStr               ; current score string to display
                LDY     #ScoreVRAM              ; position on screen
                JSR     DisplayScore            ; display it
                LDX     #HighScoreStr           ; high score string to display
                LDY     #HighScoreVRAM          ; position on screen
                JSR     DisplayScore            ; display it
                LDX     #TotalPiecesStr         ; total pieces string to display
                LDY     #TotalPiecesVRAM        ; position on screen
                JSR     DisplayScore            ; display it
                ENDM
*----------------------------------------------------------------------------------------------------------------------
SPETRIS         LDU     #UserStack              ; init user stack pointer
                JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     RandomizeSeed           ; randomize the seed with the current timer
                JSR     DisplayIntro            ; display the intro message and wait for a key to be pressed
startGame       JSR     NewGame                 ; initialize new game data and screen
startRound      JSR     NewRound                ; initialize this round (a round is what handle one piece in the game)
                JSR     CopyPieces              ; first check if it would fit
                JSR     DoesPieceFit
                _HRF    #FPieceFits
                LBEQ    endGame
roundLoop       _HRF    #FRefreshScreen         ; zero flag will be set if flag is disabled
                BEQ     sleep                   ; zero flag unset: no screen refresh needed
                JSR     DrawField               ; draw current state of the field
                JSR     DrawCurrPiece           ; draw current piece
                _DRSCRS                         ; draw scores
                _CRF    #FRefreshScreen         ; clear the refresh screen flag
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
                JSR     KeyPressed
                _HRF    #FQuitGame
                BNE     exitGame
chkForceDown    _HRF    #FForceDown
                LBEQ    roundLoop
                JSR     CopyPieces              ; TODO necessary to call again?
                LDX     #Piece2
                INC     PieceY,X
                JSR     DoesPieceFit
                _HRF    #FPieceFits
                BEQ     lockPiece               ; it doesnt, we lock*
                LDX     #Piece1                 ; it does, increment in piece1
                INC     PieceY,X
                _CRF    #FForceDown
                JMP     roundLoop
lockPiece       JSR     LockPiece
                JSR     CheckForLines
                _HRF    #FHasLines
                LBEQ    startRound
                JSR     DrawField
                LDB     #$ff                    ; TODO
loopSleep       JSR     Sleep
                DECB
                BNE     loopSleep
                JSR     RemoveLines
                JMP     startRound
endGame         JSR     GameOver                ; game over message, zero flag is set if a new game is requested
                BNE     exitGame
                JMP     startGame               ; and go back to game initialization
exitGame        JSR     RestoreVideoRAM         ; restore video ram
                RTS
*======================================================================================================================
* SaveVideoRam: saves the current video RAM into a buffer to be restored on exit
*----------------------------------------------------------------------------------------------------------------------
SaveVideoRAM    PSHU    A,X,Y,CC                ; save registers
                LDX     #VideoRAMBuffer         ; X points to the saved buffer video ram
                LDY     #VideoRAM               ; Y points to the beginning of the video ram
svLoop          LDA     ,Y+                     ; Load in A the byte of video ram
                STA     ,X+                     ; And store it in the saved buffer
                CMPY    #EndVideoRAM            ; At the end of the video ram?
                BNE     svLoop
                PULU    A,X,Y,CC                ; restore registers
                RTS
VideoRAMBuffer  RMB     32*16                   ; 16 lines of 32 chars
*======================================================================================================================
* RestoreVideoRAM: restores the video ram from the buffer
*----------------------------------------------------------------------------------------------------------------------
RestoreVideoRAM PSHU    A,X,Y,CC                ; save registers
                LDX     #VideoRAMBuffer         ; X points to the saved buffer video ram
                LDY     #VideoRAM               ; Y points to the beginning of the video ram
rvLoop          LDA     ,X+                     ; Load in A the saved video byte
                STA     ,Y+                     ; And put in in real video ram
                CMPY    #EndVideoRAM            ; At the end of the video ram?
                BNE     rvLoop
                PULU    A,X,Y,CC                ; restore registers
                RTS
*======================================================================================================================
* CopyPieces: Copy Piece1 into Piece2
*----------------------------------------------------------------------------------------------------------------------
CopyPieces      PSHU    A,B,X,Y,CC
                LDX     #Piece1
                LDY     #Piece2
                LDB     #PieceDescLen
cpLoop          LDA     ,X+
                STA     ,Y+
                DECB
                BNE     cpLoop
                PULU    A,B,X,Y,CC
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
PrintString     PSHU    A,X,Y,CC                ; save registers
                LEAY    [,X++]                  ; load the first two bytes in Y and advance X to start of string
psLoop          LDA     ,X+                     ; load char from string
                ANDA    #%00111111              ; keep the right 6 bits
                BEQ     psEnd                   ; exit loop if char is end of string
                STA     ,Y+                     ; display it
                JMP     psLoop                  ; and loop
psEnd           PULU    A,X,Y,CC                ; restore registers
                RTS
*======================================================================================================================
* ClsRight: clear the right side of the screen and print the game name at the top
*----------------------------------------------------------------------------------------------------------------------
ClsRight        PSHU    A,B,X,CC                ; save registers
                LDA     #' '                    ; char to clear the screen
                LDX     #VideoRAM               ; x points to the beginning of the video ram
crLoop0         LDB     #32-FieldWidth          ; number of cols on the right side of the field
                LEAX    FieldWidth,X            ; move x to the right side of the field
crLoop1         STA     ,X+                     ; put the char on screen
                DECB
                BNE     crLoop1                 ; haven't reach the end of the line
                CMPX    #EndVideoRAM            ; check if we are done completely
                BNE     crLoop0
                LDX     #GameTitle              ; load in x the displayable game title
                JSR     PrintString             ; print it
                PULU    A,B,X,CC                ; restore registers
                RTS
*======================================================================================================================
* InitField: Clears the field and set the left and right side characters
*----------------------------------------------------------------------------------------------------------------------
InitField       PSHU    A,B,Y,CC
                LDY     #Field
                LDA     #ChSpc                  ; erase with this car
ifLoopClear     STA     ,Y+                     ; put in video ram
                CMPY    #FieldBottom            ; until we hit bottom of field
                BNE     ifLoopClear
                LDY     #Field                  ; reset to beginning of field
                LDA     #ChFieldLeft            ; will draw left and right sides using the chars in A and B
                LDB     #ChFieldRight
ifLoop0         STA     ,Y                      ; store A at the beginning of the field row
                STB     (FieldWidth-1),Y        ; store B at the end of the field row
                LEAY    FieldWidth,Y            ; go next row
                CMPY    #FieldBottom            ; hit bottom?
                BNE     ifLoop0
                PULU    A,B,Y,CC
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
DisplayIntro    PSHU    A,X,Y,CC                ; save registers
                LDX     #Intro 
                LDY     #VideoRAM
diLoop0         LDA     ,X+
                ANDA    #%00111111              ; keep the right 6 bits
                STA     ,Y+
                CMPY    #EndVideoRAM
                BNE     diLoop0
diPollKeyboard  JSR     [POLCAT]                ; polls keyboard for any key
                BEQ     diPollKeyboard          ; poll again if no key pressed
                CMPA    #'C'                    ; check if C was press
                BNE     diCheckMono             ; no, maybe 'M'
                LDD     #PiecesColor            ; yes, use color charset
                JMP     diSaveCharset
diCheckMono     CMPA    #'M'                    ; check if M was press
                BNE     diPollKeyboard          ; no, ignore key and poll again
                LDD     #PiecesMono             ; yes, use mono charset
diSaveCharset   STD     PiecesCharset           ; save charset
                PULU    A,X,Y,CC                ; restore registers
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
* ClsRightPanel:
*----------------------------------------------------------------------------------------------------------------------
_ClsRightPanel  MACRO
                JSR     ClsRight                ; clear the right side and print the game title
                LDX     #HighScoreLabel         ; display the score label
                JSR     PrintString
                LDX     #ScoreLabel             ; display the score label
                JSR     PrintString
                LDX     #TotPiecesLabel         ; display the total pieces label
                JSR     PrintString
                ENDM
*----------------------------------------------------------------------------------------------------------------------
*======================================================================================================================
* NewGame: initializes the variables for a new game, prepares the field and do an initial drawing of the screen
*----------------------------------------------------------------------------------------------------------------------
NewGame         PSHU    A,B,X,CC                ; save registers
                LDD     #0                      
                STD     TotalPieces             ; reset total pieces
                STD     Score                   ; reset score
                LDX     #ScoreStr               ; reset score string
                JSR     IntToStr                
                LDA     #'0'
                STA     4,X                
                LDA     #IncrSpeedEvery         ; set speed counts to default
                STA     IncrSpeedCount
                CLR     SpeedCount
                LDA     #$FF                    ; reset speed for piece
                STA     SpeedForPiece                
                JSR     InitField               ; initialize field
                JSR     DrawField               ; display the field on the left
                _ClsRightPanel
                LDX     #NextPieceLabel         ; display the next piece lable
                JSR     PrintString
                JSR     GetNextPiece            ; initialize next piece
                PULU    A,B,X,CC                ; restore registers
                RTS
*======================================================================================================================
* GetNextPiece:
*----------------------------------------------------------------------------------------------------------------------
GetNextPiece    PSHS    A,B,X,U,CC                ; save registers on the system stack
                LDX     #Piece1
                LDA     NextPiece
                STA     PieceId,X
                LDA     #(FieldWidth/2)-2
                STA     PieceX,X
                CLR     PieceY,X
                CLR     PieceRot,X
                LDD     #7                      ; random number from 1 to 7
                JSR     $B4F4                   ; copy D into FPAC 0 (Floating point accumulator)
                JSR     $BF1F                   ; generate a random number
                JSR     $B3ED                   ; retrieve FPAC 0; D= your random number
                DECB                            ; decrement by 1 because number is between 1 and 7
                STB     NextPiece
                PULS    A,B,X,U,CC              ; restore registers from the system stack
                RTS
*======================================================================================================================
* DrawNextPiece:
*----------------------------------------------------------------------------------------------------------------------
DrawNextPiece   PSHU    A,B,X,Y,CC
                ;LDX     #PiecesColor            ; get the char to draw
                LDX     PiecesCharset
                LDA     NextPiece                ; by indexing PiecesCharset
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
NewRound        PSHU    A,B,CC
                CLR     RoundFlags              ; clear the flags for this round
                _SRF    #FRefreshScreen         ; will refresh screen at the start of this round
                JSR     GetNextPiece
                LDD     TotalPieces             ; increment total pieces count
                ADDD    #1
                STD     TotalPieces             ; save it and update the string version
                LDX     #TotalPiecesStr
                JSR     IntToStr                ; and update the score str for display
                DEC     IncrSpeedCount
                LDA     IncrSpeedCount          ; check if we need to increase speed
                BNE     nrNoIncr
                LDA     SpeedForPiece
                SUBA    #SpeedBump
                STA     SpeedForPiece
                LDA     #IncrSpeedEvery         ; reset the incr speed every piece counter
                STA     IncrSpeedCount
nrNoIncr        LDA     SpeedForPiece
                STA     Speed
                JSR     DrawNextPiece
                PULU    A,B,CC
                RTS
*======================================================================================================================
* Sleep:        Loops by doing nothing for a little while
*----------------------------------------------------------------------------------------------------------------------
Sleep           PSHU    D,CC
                LDD     #SleepTime
sleepLoop       SUBD    #1
                BNE     sleepLoop
                PULU    D,CC
                RTS
*======================================================================================================================
* IncScore:     increments score by at least 25 (one piece was lock)
*               then by (1 << lines) * 100
*               It will also set the high score if new score is higher
*               and prepare the strings variables for both
* A (r)         nbLines
* Score (rw)    the current score
*----------------------------------------------------------------------------------------------------------------------
IncScore        PSHU    A,B,X,CC                ; save registers
                CLRB
                CMPA    #0                      ; check if there are lines points
                BEQ     isAdd25                 ; no, just the 25
                LDB     #1                      ; will shift 1 left by the number of lines
isShift         LSLB                            ; shift b to the left
                DECA                            ; decrement lines count
                BNE     isShift                 ; shift again if more lines
                LDA     #100                    ; will multiply b by 100
                MUL
isAdd25         ADDD    #25                     ; add the mininal 25
                ADDD    Score                   ; add the current score
                STD     Score                   ; and save it
                LDX     #ScoreStr
                JSR     IntToStr                ; and update the score str for display
                CMPD    HighScore               ; compare with current high score
                BLT     endIncScore             ; smaller, no update
                STD     HighScore
                LDX     #HighScoreStr
                JSR     IntToStr
endIncScore     PULU    A,B,X,CC                ; restore registers
                RTS
*======================================================================================================================
* DisplayScore:
* X (r)         The score variable
* Y (r)         The video address where the score should be written
*----------------------------------------------------------------------------------------------------------------------
DisplayScore    PSHU    A,B,X,Y,CC              ; save registers
                LDB     #5                      ; score is 5 chars long #TODO constants or check of end of string
lpDisplayScore  LDA     ,X+
                STA     ,Y+
                DECB
                BNE     lpDisplayScore
                PULU    A,B,X,Y,CC              ; restore registers
                RTS
*======================================================================================================================
* GameOver: displays the final score and ask for a new game
*
* CC (w)        Sets the zero flag if the user wants a new game
*----------------------------------------------------------------------------------------------------------------------
GameOver        PSHU    X,Y
                _ClsRightPanel
                _DRSCRS                         ; draw scores
                LDX     #GameOverLabel          ; display game over message
                JSR     PrintString
                LDD     Score                   ; check if new high score
                CMPD    HighScore
                BLT     goAskNewGame            ; no new high score
                LDX     #NewHiScoreLabel
                JSR     PrintString
goAskNewGame    LDX     #AskNewGameLabel        ; ask for a new game
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
*======================================================================================================================
* IntToStr: convert an unsigned integer to a string. Stolen from Coco SDC-Explorer :)
*
* D (r):        Unsigned integer value
* X (r):        buffer pointer (should be at least 6 bytes)
*----------------------------------------------------------------------------------------------------------------------
IntToStr        PSHU	X,Y,A,B,CC
                JSR	ITOA003
                LDX     3,U
                LDB     #' '
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
*======================================================================================================================
* KeyPressed:   Checks the key pressed and try the following actions:
*               Arrow key left:         Move 1 left
*               Arrow key right:        Move 1 right
*               Arrow key up:           Rotate the piece
*               Arrow key down:         Move 1 down
*               Space Bar:              Fall piece until collision
*               P:                      Pause game
*               Break:                  Exit game instantly              
*
* A (r):        The key pressed
*----------------------------------------------------------------------------------------------------------------------
KeyPressed      PSHU    A,B,X,Y,CC              ; save registers
                LDX     #Piece1                 ; Piece1 is the current piece
                LDY     #Piece2                 ; Piece2 is used to test if it fits
                CMPA    #KeyLeft                ; was the key press the left arrow key?
                BEQ     kpLeft
                CMPA    #KeyRight               ; right arrow key?
                BEQ     kpRight
                CMPA    #KeyUp                  ; up arrow key?
                BEQ     kpUp
                CMPA    #KeyDown                ; down arrow key?
                LBEQ    kpDown
                CMPA    #' '                    ; spacebar key?
                LBEQ    kpSpace
                CMPA    #KeyEscape              ; break key?
                LBEQ    kpBreak
                CMPA    #'P'                    ; P key? 
                LBEQ    kpP
                JMP     kpEnd                   ; ignore other keys
kpLeft          DEC     PieceX,Y                ; decrement X in piece2
                JSR     DoesPieceFit            ; check if it fits
                _HRF    #FPieceFits
                LBEQ    kpEnd
                DEC     PieceX,X                ; it fits, decrement X in piece1
                _SRF    #FRefreshScreen         ; and will have to refresh screen
                JMP     kpEnd
kpRight         INC     PieceX,Y                ; increment X in piece2
                JSR     DoesPieceFit            ; check if it fits
                _HRF    #FPieceFits
                LBEQ    kpEnd
                INC     PieceX,X                ; it fits, increment X in piece1
                _SRF    #FRefreshScreen         ; and will have to refresh screen
                JMP     kpEnd
kpUp            INC     PieceRot,Y              ; increment rotation in piece2
                LDA     PieceRot,Y              ; load in a for comparison
                CMPA    #MaxRotations
                BNE     kpUpEnd                 ; reset to 0 if over 4
                CLRA
kpUpEnd         STA     PieceRot,Y              ; update piece2
                JSR     DoesPieceFit            ; check if it fits
                _HRF    #FPieceFits
                BEQ     kpEnd
                LDA     PieceRot,Y              ; it fits, update piece1
                STA     PieceRot,X
                _SRF    #FRefreshScreen         ; and will have to refresh screen
                JMP     kpEnd
kpDown          INC     PieceY,Y                ; increment Y in piece2
                JSR     DoesPieceFit            ; check if it fits
                _HRF    #FPieceFits
                BEQ     kpEnd
                INC     PieceY,X                ; it fits, increments Y in piece1
                _SRF    #FRefreshScreen         ; and will have to refresh screen
                JMP     kpEnd
kpSpace         _SRF    #FFalling               ; set the falling flag to on
                JMP     kpEnd
kpBreak         _SRF    #FQuitGame              ; set the quit game to exit round loop and game
                JMP     kpEnd
kpP             LDX     #PausedLabel            ; print "paused" message
                JSR     PrintString
kpPollKeyboard  JSR     [POLCAT]                ; polls keyboard for any key
                BEQ     kpPollKeyboard          ; poll again if no key pressed
                LDY     ,X                      ; get the vram address of the pause message still in X
                LDA     #' '                    ; space char to erase with
                LDB     PausedLabelLen          ; length
kpLoopPause0    STA     ,Y+                     ; put in video ram
                DECB
                BNE     kpLoopPause0            ; loop if there's more to erase
kpEnd           PULU    A,B,X,Y,CC              ; restore registers
                RTS
*======================================================================================================================
* DrawCurrPiece
*----------------------------------------------------------------------------------------------------------------------
DrawCurrPiece   PSHU    A,B,X,Y,CC
                LDX     #Piece1
                LDY     PiecesCharset
                LDA     PieceId,X               ; by indexing PiecesCharset
                LDA     A,Y
                STA     dcpDrawChar             ; the char used to draw
                LDX     #Piece1
                LDA     #32                     ; 32 cols per line
                LDB     PieceY,X                ; y position
                MUL
                ADDB    PieceX,X                ; add x position
                ADDD    #VideoRAM               ; add base pointer
                PSHU    D
                ADDD    #(3*32)+4               ; where we stop to draw
                STD     dcpDrawEndAddr
                LDA     PieceId,X               ; compute the offset in the pieces struct array
                LDB     #PieceStructLen
                MUL
                ADDD    #Pieces                 ; add base pointer
                TFR     D,Y                     ; X now points to the beginning of the piece struct to draw
                LDA     #PieceLen               ; Compute the offset for the rotation
                LDB     PieceRot,X
                MUL
                LEAX    D,Y                     ; x now should point to the good rotated shape to draw
                PULU    Y                       ; Y == video memory where we start to draw
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
*======================================================================================================================
* DoesPieceFit
*----------------------------------------------------------------------------------------------------------------------
DoesPieceFit    PSHU    A,B,X,Y,CC              ; save registers
                LDX     #Piece2
                _SRF    #FPieceFits             ; piece fit by default
                LDB     PieceY,X
                LDA     #FieldWidth             ; cols per line
                MUL
                ADDB    PieceX,X                ; add X
                ADDD    #Field
                PSHU    D
                ADDD    #(3*FieldWidth)+4       ; where we stop to check
                STD     dpfFieldEndAddr
                LDA     PieceId,X
                LDB     #PieceStructLen
                MUL
                ADDD    #Pieces
                TFR     D,Y                     ; X now points to the beginning of the piece struct to check
                LDA     #PieceLen
                LDB     PieceRot,X
                MUL
                LEAX    D,Y                     ; x now should point to the good rotated shape to draw
                PULU    Y                       ; Y == field pos where we start to check
dpfLoopRow0     LDB     #4                      ; 4 "pixels' per row
dpfLoopRow1     LDA     ,X+
                CMPA    #ChDot
                BNE     dpfCheck                ; not a dot, we must check
                LEAY    1,Y                     ; won't check but still need to move to next pos on the field
                JMP     dpfEndCheck
dpfCheck        LDA     ,Y+                     ; the char to draw, from the stack
                CMPA    #ChSpc
                BEQ     dpfEndCheck
                _CRF    #FPieceFits             ; piece does not fit
                JMP     dpfEnd
dpfEndCheck     DECB
                BNE     dpfLoopRow1
                CMPY    dpfFieldEndAddr         ; are we done checking?
                BGE     dpfEnd
                LEAY    (FieldWidth-4),Y        ; move at the beginning of next line on video ram (32-width=28)
                JMP     dpfLoopRow0
dpfEnd          PULU    A,B,X,Y,CC              ; restore the registers
                RTS
dpfFieldEndAddr FDB     0
*======================================================================================================================
* LockPiece:
*----------------------------------------------------------------------------------------------------------------------
LockPiece       PSHU    A,B,X,Y,CC              ; save registers
                LDX     #Piece1
                LDY     PiecesCharset
                LDA     PieceId,X               ; by indexing PiecesCharset
                LDA     A,Y
                STA     lcpDrawChar             ; the char used to draw
                LDB     PieceY,X
                LDA     #FieldWidth             ; cols per line
                MUL
                ADDB    PieceX,X                ; add X
                ADDD    #Field
                PSHU    D
                ADDD    #(3*FieldWidth)+4       ; where we stop to check
                STD     lcpFieldEndAddr
                LDA     PieceId,X
                LDB     #PieceStructLen
                MUL
                ADDD    #Pieces
                TFR     D,Y                     ; X now points to the beginning of the piece struct to check
                LDA     #PieceLen
                LDB     PieceRot,X
                MUL
                LEAX    D,Y                     ; x now should point to the good rotated shape to draw
                PULU    y                       ; Y == field pos where we start to check
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
lcpEnd          PULU    A,B,X,Y,CC              ; restore the registers
                RTS
lcpDrawChar     FCB     0
lcpFieldEndAddr FDB     0
*======================================================================================================================
* CheckForLines: goes through the field and check if there are any full lines
* this routine also updates the score by at least 25pts (we are called because a piece is locked)
* and by (1 << nblines) * 100
*----------------------------------------------------------------------------------------------------------------------
CheckForLines   PSHU    A,B,X,Y,CC
                _CRF    #FHasLines              ; clear the has lines flag
                CLR     linesCount              ; clear the lines count
                LDX     #Field                  ; X points to the top of the field
cflCheckRow     LDB     #FieldWidth-2           ; will check the row backward, ignoring the left and right border
cflLoop0        LDA     B,X                     ; load in a the field charact
                CMPA    #ChSpc                  ; is it a space?
                BEQ     cflNextRow              ; yeah, so not a line, look next row
                DECB                            ; no, keep looking previous char on row
                BNE     cflLoop0                ; loop if we haven't reach left side
                _SRF    #FHasLines              ; no space found on the row, we have a line
                INC     linesCount              ; increment the number of lines found
                LDB     #FieldWidth-2           ; mark the line in the field for display
                LDA     #ChLine                 ; by using the line char
cflLoop1        STA     B,X
                DECB
                BNE     cflLoop1
cflNextRow      LEAX    FieldWidth,X            ; go on to next row
                CMPX    #FieldBottom            ; check if we reach the bottom of the field
                BLT     cflCheckRow             ; no, loop
                LDA     linesCount              ; increment the score, lines count has to be in A
                JSR     IncScore                ; call sub routine to compute new score
                PULU    A,B,X,Y,CC
                RTS
linesCount      FCB     0
*======================================================================================================================
* RemoveLines
*----------------------------------------------------------------------------------------------------------------------
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
Field           RMB     FieldWidth*16           ; 16 rows of 12 cols
FieldBottom     FCC     /############/          ; won't be displayed but used for collisions
*======================================================================================================================
* Game constants
*----------------------------------------------------------------------------------------------------------------------
POLCAT	        EQU	$A000	                ; read keyboard ROM routine
MaxRotations    EQU     4
SleepTime       EQU     $ff
VideoRAM        EQU     $400                    ; video ram address
EndVideoRAM     EQU     $600
*======================================================================================================================
* Piece descriptors
* Piece1 is used for the current piece in the field
* Piece2 is used to check for a potential piece fit in the field
*----------------------------------------------------------------------------------------------------------------------
PieceDescLen    EQU     4
PieceId         EQU     0
PieceX          EQU     1
PieceY          EQU     2
PieceRot        EQU     3
Piece1          RMB     PieceDescLen
Piece2          RMB     PieceDescLen
*======================================================================================================================
* Game variables
*----------------------------------------------------------------------------------------------------------------------
Score           FDB     0
ScoreStr        RMB     6
HighScore       FDB     0
HighScoreStr    FCC     /    0 /                ; only initialized here, won't overwrite on second exec
NextPiece       FCB     0
SpeedForPiece   FCB     0                       ; default max speed value for this piece
Speed           FCB     0                       ; max speed value for this speed
SpeedCount      FCB     0                       ; will used to be count speed in a round
IncrSpeedEvery  EQU     15                      ; increase speed every X pieces
IncrSpeedCount  FCB     0
SpeedBump       EQU     16                      ; speed is increased by this number every X pieces
TotalPieces     FDB     0                       
TotalPiecesStr  RMB     6
RoundFlags      FCB     0                       ; different flags for a round using the following constants
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
PiecesMono      FCC     /ABCDEFG/
PiecesCharset   FDB     0                       ; ptr to either PiecesColor or PiecesMono
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
Intro           FCC     /         S P E T R I S !        /      ; 1
                FCC     /                                /      ; 2
                FCC     /CHOOSE DISPLAY MODE:            /      ; 3
                FCC     /                                /      ; 4
                FCC     /[C]OLOR                         /      ; 5
                FCC     /[M]ONOCHROME                    /      ; 6
                FCC     /                                /      ; 7
                FCC     /KEYBOARD GAME CONTROLS:         /      ; 8
                FCC     /                                /      ; 9
                FCC     /LEFT ARROW      MOVE PIECE LEFT /      ; 10
                FCC     /RIGHT ARROW     MOVE PIECE RIGHT/      ; 11
                FCC     /UP ARROW        ROTATE PIECE    /      ; 12
                FCC     /DOWN ARROW      MOVE PIECE DOWN /      ; 13
                FCC     /SPACE BAR       DROP PIECE      /      ; 14
                FCC     /P               PAUSE GAME      /      ; 15
                FCC     /BREAK           EXIT GAME       /      ; 16
GameTitle       FDB     VideoRAM+FieldWidth+7
                FCC     /SPETRIS!@/
HighScoreLabel  FDB     VideoRAM+(32*2)+FieldWidth+1
                FCC     /HIGH SCORE:@/
HighScoreVRAM   EQU     VideoRAM+(32*2)+FieldWidth+1+14
ScoreLabel      FDB     VideoRAM+(32*3)+FieldWidth+1
                FCC     /SCORE:@/
ScoreVRAM       EQU     VideoRAM+(32*3)+FieldWidth+1+14
TotPiecesLabel  FDB     VideoRAM+(32*4)+FieldWidth+1
                FCC     /TOTAL PIECES:@/
TotalPiecesVRAM EQU     VideoRAM+(32*4)+FieldWidth+1+14
NextPieceLabel  FDB     VideoRAM+(32*6)+FieldWidth+1
                FCC     /NEXT PIECE:@/
NextPieceVRAM   EQU     VideoRAM+(32*8)+FieldWidth+1
NextPieceVRAME  EQU     VideoRAM+(32*11)+FieldWidth+1+4
PausedLabelLen  EQU     6                
PausedLabel     FDB     VideoRAM+(32*15)+FieldWidth+8
                FCC     /PAUSED@/
GameOverLabel   FDB     VideoRAM+(32*8)+FieldWidth+1+3
                FCC     /GAME OVER :(@/
NewHiScoreLabel FDB     VideoRAM+(32*10)+FieldWidth+1+2
                FCC     /NEW HIGH SCORE!@/
AskNewGameLabel FDB     VideoRAM+(32*15)+FieldWidth+1+3
                FCC     \NEW GAME? Y/N@\
*======================================================================================================================
* User stack (end of program)
*----------------------------------------------------------------------------------------------------------------------
                RMB     32                      ; user stack space TODO maybe even less or more????
UserStack       EQU     *                       ; have the user stack at the end of the program
                END     SPETRIS
