*******************************************************************************
* Tetris for my Color Computer 3                                              *
*******************************************************************************
                ORG     $3F00
Start           JSR     SaveVideoRAM            ; save video ram to restore on exit
                *JSR     ClearScreen
                JSR     DrawInfo
                JSR     DrawNextPiece
                JSR     DrawField
GetKey          JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey                  ; Loop back if nothing
                JSR     RestoreVideoRAM         ; Cleanup and end execution
                RTS
*******************************************************************************
ClearScreen     LDY     #VideoRAM               ; Y points to the real video ram
                LDA     #ChSpc
csLoop1         STA     ,Y+                     ; Put A in video ram
                CMPY    #$600                   ; End of video ram?
                BNE     csLoop1                 ; Loop if more to display
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
                *PULU    A                       ; calculate the offset from Pieces
                *LDB     #PiecesLength
                *MUL
                *ADDD    Pieces 
                LDX     #Pieces 
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
DrawNextPiece   *LDX     #Pieces                 ; Piece to draw
                *LDA     #(FieldWidth+2)         ; X Position
                *LDB     #5                      ; Y Position
                LDA     #0 ;#Pieces                 ; Piece to draw 1st param
                PSHU    A
                LDA     #5                      ; Y Position 3rd param
                PSHU    A
                LDD     #(FieldWidth+2)         ; X Position 2nd param
                PSHU    D
                JSR     DrawPiece
*                LDY     #(VideoRAM+(32*5)+FieldWidth+2)
*                
*dnLoop1         LDB     #4
*dnLoop2         LDA     ,X+
*                STA     ,Y+
*                DECB
*                BNE     dnLoop2
*                TFR     Y,D
*                ADDD    #28                
*                TFR     D,Y
*                CMPY    #(VideoRAM+(32*10)+FieldWidth+2)
*                BNE     dnLoop1
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
drawPieceBlock  FCB     128 ;65
PiecesLength    EQU     16
Pieces          FCC     /..X...X...X...X./
                FCC     /..X..XX...X...../
                FCC     /.....XX..XX...../
                FCC     /..X..XX..X....../
                FCC     /.X...XX...X...../
                FCC     /.X...X...XX...../
                FCC     /..X...X..XX...../
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
                FCC     /``/
                FCB     $5E
                FCC     /z`ROTATE`````````/
                FCC     /``/
                FCB     $5F
                FCC     /z`DOWN```````````/
                FCC     /``/
                FCB     $5F
                FCC     /z`LEFT```````````/
                FCC     /``/
                FCB     $5F
                FCC     /z`RIGHT``````````/
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