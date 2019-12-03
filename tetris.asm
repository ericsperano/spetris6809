*******************************************************************************
* Tetris for my Color Computer 3                                              *
*******************************************************************************
                ORG     $3F00
Start           JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     DrawInfo
                JSR     DrawField
                LDA     #0
                JSR     DrawNextPiece
GetKey0         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey0                 ; Loop back if nothing
                LDA     #1
                JSR     DrawNextPiece
GetKey1         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey1                 ; Loop back if nothing
                LDA     #2
                JSR     DrawNextPiece
GetKey2         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey2                 ; Loop back if nothing
                LDA     #3
                JSR     DrawNextPiece
GetKey3         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey3                 ; Loop back if nothing
                LDA     #4
                JSR     DrawNextPiece
GetKey4         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey4                 ; Loop back if nothing
                LDA     #5
                JSR     DrawNextPiece
GetKey5         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey5                 ; Loop back if nothing
                LDA     #6
                JSR     DrawNextPiece
GetKey6         JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey6                 ; Loop back if nothing
                JSR     RestoreVideoRAM         ; Cleanup and end execution
                RTS
*******************************************************************************               
DrawField       LDY     #VideoRAM               ; Y points to the real video ram
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
* DrawPiece: A=x B=y X=piece addr
*******************************************************************************
DrawPiece       PSHS    D
                PSHS    X
                PSHS    Y
                PULU    D                       ; pull x and store it
                STD     drawPieceX
                LDA     #32                     ; will multiply y by 32 chars
                PULU    B                       ; pull y
                MUL     
                ADDD    #VideoRAM
                ADDD    drawPieceX
                TFR     D,Y                     ; our video ram index  
                PULU    A                       ; calculate the offset from Pieces
                LDB     #PiecesLength
                MUL
                ADDD    #Pieces 
                TFR     D,X
                LDA     ,X+ 
                STA     drawPieceBlock
                *LDX     #Pieces 
dpLoop1         LDB     #4
dpLoop2         LDA     ,X+
                CMPA    #Dot
                BNE     dpDraw
                LEAY    1,Y
                JMP     dpDraw2
dpDraw          LDA     drawPieceBlock
                STA     ,Y+
dpDraw2         DECB
                BNE     dpLoop2
                LEAY    28,Y
                CMPY    #(VideoRAM+(32*9)+FieldWidth+2)
                BNE     dpLoop1
endDrawPiece    PULS    Y
                PULS    X 
                PULS    D                
                RTS

*******************************************************************************
DrawNextPiece   STA     pieceToDraw
                LDA     #7                      ; clear first
                PSHU    A                       ; Piece index to draw 3rd param
                LDA     #5                      ; Y Position 2nd param
                PSHU    A
                LDD     #(FieldWidth+2)         ; X Position 1st param
                PSHU    D
                JSR     DrawPiece
                LDA     pieceToDraw
drawNextPiece0  PSHU    A                       ; Piece index to draw 3rd param
                LDA     #5                      ; Y Position 2nd param
                PSHU    A
                LDD     #(FieldWidth+2)         ; X Position 1st param
                PSHU    D
                JSR     DrawPiece
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
*FieldHeigth     EQU     10
VideoRAM        EQU     $400                    ; video ram address
POLCAT	        EQU	    $A000	                ; read keyboard ROM routine

*SGCHAR          EQU     128+(16*(IntroColor-1)) ; base semi graphic char
ChSpc           EQU     128+(16*0)+15
ChFieldLeft     EQU     128+(16*0)+10
ChFieldRight    EQU     128+(16*0)+5

KeyUp		    EQU	$5E		                    ; UP key
KeyDown		    EQU	$0A		                    ; DOWN key
*******************************************************************************
*******************************************************************************
*******************************************************************************
drawPieceX      FDB     0
drawPieceBlock  FCB     0
pieceToDraw     FCB     0
PiecesLength    EQU     1+16               
Pieces          FCB     128+15+(16*7)  
                FCC     /..X...X...X...X./
                FCB     128+15+16
                FCC     /..X..XX...X...../
                FCB     128+15+(16*2)  
                FCC     /.....XX..XX...../
                FCB     128+15+(16*3)
                FCC     /..X..XX..X....../
                FCB     128+15+(16*4)
                FCC     /.X...XX...X...../
                FCB     128+15+(16*5)
                FCC     /.X...X...XX...../
                FCB     128+15+(16*6)
                FCC     /..X...X..XX...../
                FCB     128+15
                FCC     /XXXXXXXXXXXXXXXX/
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